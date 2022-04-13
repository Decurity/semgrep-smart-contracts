// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IDEXRouter} from './interfaces/IDEXRouter.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import "./interfaces/IBEP20.sol";
import "./interfaces/IGatewayHook.sol";
import "./interfaces/IStaking.sol";
import './Auth.sol';
import "./EarnHub.sol";
import "./interfaces/IAnyshareOracle.sol";
import "./AnyShareOracle.sol";


contract ReflectionBackedStaking is IGatewayHook, IStaking, Auth, Pausable {
    // * Event declarations
    event EnterStaking(address addr, uint256 amt);
    event LeaveStaking(address addr, uint256 amt);
    event Harvest(address addr, uint256 unpaidAmount);

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    struct TokenPool {
        uint256 totalShares;
        uint256 totalDividends;
        uint256 totalDistributed;
        uint256 dividendsPerShare;
        IBEP20 rewardsToken;
        IBEP20 stakingToken;
    }

    IDEXRouter public router;

    TokenPool public tokenPool;

    IAnyflect public anyflect = IAnyflect(0x8e3Ad8D73EE2439c3ce0A293e59C19563C2C56F5);

    EarnHub public earnHub;
    IBEP20 public rewardsToken;

    mapping(address => Share) public shares; // Shares by token vault

    mapping(address => bool) excludeSwapperRole;

    uint256 public launchedAt;

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    bool public swapping = false;

    IAnyShareOracle public anyshareOracle = IAnyShareOracle(0x0F52dF936873dE8BA1509d17F338693e54A700f1);

    constructor(
        address _router,
        IBEP20 _rewardsToken,
        IBEP20 _stakingToken,
        EarnHub _earnHub
    ) Auth(msg.sender) {
        router = _router != address(0) ? IDEXRouter(_router) : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        rewardsToken = _rewardsToken;
        tokenPool.rewardsToken = rewardsToken;
        tokenPool.stakingToken = _stakingToken;
        earnHub = _earnHub;
        launchedAt = block.timestamp;
    }

    receive() external payable {
        require(!paused(), 'Contract has been paused');

        if (swapping)
            return;

        if (!excludeSwapperRole[msg.sender]) {
            getRewardsToken(address(this).balance);
        }
    }

    // * Lets you stake stakingToken
    function enterStaking(uint256 _amt) external whenNotPaused {
        require(tokenPool.stakingToken.allowance(msg.sender, address(this)) >= _amt, 'Not enough allowance');
        _enterStaking(msg.sender, _amt, msg.sender);
    }

    function _enterStaking(address _addr, uint256 _amt, address _transferFromAddr) internal {
        if (_amt == 0) _amt = tokenPool.stakingToken.balanceOf(_addr);

        require(_amt <= tokenPool.stakingToken.balanceOf(_transferFromAddr), 'Insufficient balance to enter staking');

        earnHub.setIsFeeExempt(_transferFromAddr, true);
        bool success = tokenPool.stakingToken.transferFrom(_transferFromAddr, address(this), _amt);
        earnHub.setIsFeeExempt(_transferFromAddr, false);

        require(success, 'Failed to fetch tokens towards the staking contract');

        // Give out rewards if already staking
        if (shares[_addr].amount > 0) {
            giveStakingReward(_addr);
        }

        addShareHolder(_addr, _amt);

        anyflect.setShares(address(0x1), _addr, 0, anyshareOracle.getAnyflectShares(_addr));
        emit EnterStaking(_addr, _amt);
    }

    function leaveStaking(uint256 _amt) external {
        _leaveStaking(_amt, msg.sender);
    }

    function _leaveStaking(uint256 _amt, address _staker) internal {
        require(shares[_staker].amount > 0, 'You are not currently staking');

        // Pay native token rewards.
        if (getUnpaidEarnings(_staker) > 0) {
            giveStakingReward(_staker);
        }


        if (_amt == 0) _amt = shares[_staker].amount;
        // Update shares for address
        _removeShares(_amt, _staker);
        // Get rewards from contract
        tokenPool.stakingToken.transfer(_staker, _amt);

        emit LeaveStaking(_staker, _amt);
    }

    function reinvest() external {
        uint256 earnHubAmtObtained;
        if (tokenPool.rewardsToken == tokenPool.stakingToken) {
            earnHubAmtObtained = getUnpaidEarnings(msg.sender);
        } else {
            earnHubAmtObtained = _swapStakingRewards(getUnpaidEarnings(msg.sender));
        }
        _reinvestStake(msg.sender, earnHubAmtObtained);
    }

    function _reinvestStake(address _addr, uint256 _amt) internal {
        addShareHolder(_addr, _amt);
    }

    function giveStakingReward(address _shareholder) internal {
        require(shares[_shareholder].amount > 0, 'You are not currently staking');

        uint256 amount = getUnpaidEarnings(_shareholder);

        if (amount > 0) {
            tokenPool.totalDistributed += amount;
            shares[_shareholder].totalRealised += amount;
            shares[_shareholder].totalExcluded = getCumulativeDividends(shares[_shareholder].amount);
            rewardsToken.transfer(_shareholder, amount);
        }
    }

    function _swapStakingRewards(uint256 _amt) internal returns (uint256) {
        uint256 earnHubBalanceBefore = earnHub.balanceOf(address(this));

        address[] memory path = new address[](3);
        path[0] = address(tokenPool.rewardsToken);
        path[1] = router.WETH();
        path[2] = address(tokenPool.stakingToken);

        tokenPool.rewardsToken.approve(address(router), _amt);
        swapping = true;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amt,
            0,
            path,
            address(this),
            block.timestamp
        );
        swapping = false;

        uint256 balanceAfter = earnHub.balanceOf(address(this));

        return balanceAfter - earnHubBalanceBefore;
    }

    function harvest() external whenNotPaused {
        require(getUnpaidEarnings(msg.sender) > 0, 'No earnings yet ser');
        uint256 unpaid = getUnpaidEarnings(msg.sender);
        if (!isLiquid(getUnpaidEarnings(msg.sender))) {
            getRewardsToken(address(this).balance);
        }
        giveStakingReward(msg.sender);
        emit Harvest(msg.sender, unpaid);
    }

    function getUnpaidEarnings(address _shareholder) public view returns (uint256) {
        if (shares[_shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[_shareholder].amount);
        uint256 shareholderTotalExcluded = shares[_shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return (shareholderTotalDividends - shareholderTotalExcluded);
    }

    // * Update pool shares and user data
    function addShareHolder(address _shareholder, uint256 _amt) internal {
        tokenPool.totalShares += _amt;
        shares[_shareholder].amount += _amt;
        shares[_shareholder].totalExcluded = getCumulativeDividends(shares[_shareholder].amount);
    }

    function _removeShares(uint256 _amt, address _staker) internal {
        tokenPool.totalShares -= _amt;
        shares[_staker].amount -= _amt;
        shares[_staker].totalExcluded = getCumulativeDividends(shares[_staker].amount);
    }

    function getCumulativeDividends(uint256 _share) public view returns (uint256) {
        return _share * tokenPool.dividendsPerShare / dividendsPerShareAccuracyFactor;
    }

    function isLiquid(uint256 _amt) internal view returns (bool) {
        return rewardsToken.balanceOf(address(this)) > _amt;
    }

    function getRewardsTokenPath() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(rewardsToken);
        return path;
    }

    function getRewardsToken(uint256 _amt) internal returns (uint256) {
        if (tokenPool.totalShares == 0)
            return 0;
        uint256 balanceBefore = rewardsToken.balanceOf(address(this));

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : _amt}(
            0,
            getRewardsTokenPath(),
            address(this),
            block.timestamp
        );

        uint256 amount = (rewardsToken.balanceOf(address(this)) - balanceBefore);

        tokenPool.totalDividends += amount;
        tokenPool.dividendsPerShare += (dividendsPerShareAccuracyFactor * amount / tokenPool.totalShares);
        return amount;
    }

    // * Enables hopping between staking pools
    // ! Authorize all pools to enable hops.
    function makeHop(IStaking _newPool) external override {
        require(shares[msg.sender].amount > 0, 'Not enough in stake to hop');
        uint256 amt = shares[msg.sender].amount;
        // Pay native token rewards.
        if (getUnpaidEarnings(msg.sender) > 0) {
            giveStakingReward(msg.sender);
        }
        _removeShares(amt, msg.sender);
        tokenPool.stakingToken.approve(address(_newPool), tokenPool.stakingToken.totalSupply());
        // todoruleid: basic-reentrancy
        _newPool.receiveHop(amt, msg.sender, payable(address(this)));
    }

    // * Has to be authorized due to being able to spoof a ReflctionBackedStaking contract, enabling phishing venues for scammers.
    function receiveHop(uint256 _amt, address _addr, address payable _oldPool) external override authorized {
        require(tokenPool.stakingToken.allowance(_oldPool, address(this)) >= _amt, 'Not enough allowance');

        _enterStaking(_addr, _amt, _oldPool);
    }

    // * [START] Setter Functions
    function pause(bool _pauseStatus) external authorized {
        if (_pauseStatus) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setSwapperExcluded(address _addr, bool _excluded) external authorized {
        excludeSwapperRole[_addr] = _excluded;
    }

    function lunch() external authorized {
        launchedAt = block.timestamp;
    }

    function setStakingToken(IBEP20 _stakingToken) external authorized {
        tokenPool.stakingToken = _stakingToken;
    }

    function setRewardToken(IBEP20 _rewardToken) external authorized {
        rewardsToken = _rewardToken;
        tokenPool.rewardsToken = _rewardToken;
    }

    function setEarnHub(EarnHub _earnHubToken) external authorized {
        earnHub = _earnHubToken;
    }

    function setAnyFlect(IAnyflect _anyflect) external authorized {
        anyflect = _anyflect;
    }
    // * [END] Setter Functions

    // * [START] IGatewayHook functions
    function process(EarnHubLib.Transfer memory transfer, uint256 gasLimit) external override(IGatewayHook) {

    }

    function depositBNB() external payable override (IGatewayHook) {
        if (!excludeSwapperRole[msg.sender]) {
            getRewardsToken(address(this).balance);
        }
    }

    function excludeFromProcess(bool val) external override (IGatewayHook) {
        excludeSwapperRole[msg.sender] = true;
    }
    // * [END] IGatewayHook functions

    // * [START] Auxiliary Functions
    // Grabs any shitcoin someone sends to our contract, converts it to rewards for our holders ♥
    function fuckShitcoins(IBEP20 _shitcoin, address[] memory _path) external authorized {

        require(
            address(_shitcoin) != address(rewardsToken) ||
            address(_shitcoin) != address(tokenPool.stakingToken),
            "Hey this is a safe space"
        );


        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _shitcoin.balanceOf(address(this)),
            0,
            _path,
            address(this),
            block.timestamp
        );
    }

    function emergencyWithdraw() external {
        tokenPool.stakingToken.transfer(msg.sender, shares[msg.sender].amount);
        _removeShares(shares[msg.sender].amount, msg.sender);
    }

    function rescueSquad(address payable _to) external authorized {
        (bool succ,) = _to.call{value : address(this).balance}("");
        require(succ, "unable to send value, recipient may have reverted");
    }

    function rescueSquadTokens(address _to) external authorized {
        rewardsToken.transfer(_to, rewardsToken.balanceOf(address(this)));
        earnHub.transfer(_to, earnHub.balanceOf(address(this)));
    }

    function setAnyShareOracle(IAnyShareOracle _oracle) external authorized {
        anyshareOracle = _oracle;
    }
    // * [END] Auxiliary Functions

}
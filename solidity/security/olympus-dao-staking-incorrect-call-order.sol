// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IsFLOOR.sol";
import "./interfaces/IgFLOOR.sol";
import "./interfaces/IDistributor.sol";

import "./types/FloorAccessControlled.sol";

contract FloorStaking is FloorAccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IsFLOOR;
    using SafeERC20 for IgFLOOR;

    /* ========== EVENTS ========== */

    event DistributorSet(address distributor);
    event WarmupSet(uint256 warmup);

    /* ========== DATA STRUCTURES ========== */

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    struct Claim {
        uint256 deposit; // if forfeiting
        uint256 gons; // staked balance
        uint256 expiry; // end of warmup period
        bool lock; // prevents malicious delays for claim
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable FLOOR;
    IsFLOOR public immutable sFLOOR;
    IgFLOOR public immutable gFLOOR;

    Epoch public epoch;

    IDistributor public distributor;

    mapping(address => Claim) public warmupInfo;
    uint256 public warmupPeriod;
    uint256 private gonsInWarmup;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _floor,
        address _sFLOOR,
        address _gFLOOR,
        uint256 _epochLength,
        uint256 _firstEpochNumber,
        uint256 _firstEpochTime,
        address _authority
    ) FloorAccessControlled(IFloorAuthority(_authority)) {
        require(_floor != address(0), "Zero address: FLOOR");
        FLOOR = IERC20(_floor);
        require(_sFLOOR != address(0), "Zero address: sFLOOR");
        sFLOOR = IsFLOOR(_sFLOOR);
        require(_gFLOOR != address(0), "Zero address: gFLOOR");
        gFLOOR = IgFLOOR(_gFLOOR);

        epoch = Epoch({length: _epochLength, number: _firstEpochNumber, end: _firstEpochTime, distribute: 0});
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice stake FLOOR to enter warmup
     * @param _to address
     * @param _amount uint
     * @param _claim bool
     * @param _rebasing bool
     * @return uint
     */
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256) {
        //ruleid: olympus-dao-staking-incorrect-call-order
        FLOOR.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = _amount.add(rebase()); // add bounty if rebase occurred
        if (_claim && warmupPeriod == 0) {
            return _send(_to, _amount, _rebasing);
        } else {
            Claim memory info = warmupInfo[_to];
            if (!info.lock) {
                require(_to == msg.sender, "External deposits for account are locked");
            }

            warmupInfo[_to] = Claim({
                deposit: info.deposit.add(_amount),
                gons: info.gons.add(sFLOOR.gonsForBalance(_amount)),
                expiry: epoch.number.add(warmupPeriod),
                lock: info.lock
            });

            gonsInWarmup = gonsInWarmup.add(sFLOOR.gonsForBalance(_amount));

            return _amount;
        }
    }


    /**
     * @notice trigger rebase if epoch over
     * @return uint256
     */
    function rebase() public returns (uint256) {
        uint256 bounty;
        if (epoch.end <= block.timestamp) {
            sFLOOR.rebase(epoch.distribute, epoch.number);

            epoch.end = epoch.end.add(epoch.length);
            epoch.number++;

            if (address(distributor) != address(0)) {
                distributor.distribute();
                bounty = distributor.retrieveBounty(); // Will mint floor for this contract if there exists a bounty
            }
            uint256 balance = FLOOR.balanceOf(address(this));
            uint256 staked = sFLOOR.circulatingSupply();
            if (balance <= staked.add(bounty)) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub(staked).sub(bounty);
            }
        }
        return bounty;
    }

}


contract QWAStaking is Ownable {

    /// DATA STRUCTURES ///

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    /// STATE VARIABLES ///

    /// @notice QWA address
    IERC20 public immutable QWA;
    /// @notice sQWA address
    IsQWA public immutable sQWA;

    /// @notice Current epoch details
    Epoch public epoch;

    /// @notice Distributor address
    IDistributor public distributor;

    /// CONSTRUCTOR ///

    /// @param _QWA                   Address of QWA
    /// @param _sQWA                  Address of sQWA
    /// @param _epochLength            Epoch length
    /// @param _secondsTillFirstEpoch  Seconds till first epoch starts
    constructor(
        address _QWA,
        address _sQWA,
        uint256 _epochLength,
        uint256 _secondsTillFirstEpoch
    ) {
        QWA = IERC20(_QWA);
        sQWA = IsQWA(_sQWA);

        epoch = Epoch({
            length: _epochLength,
            number: 0,
            end: block.timestamp + _secondsTillFirstEpoch,
            distribute: 0
        });
    }

    /// MUTATIVE FUNCTIONS ///

    /// @notice stake QWA
    /// @param _to address
    /// @param _amount uint
    function stake(address _to, uint256 _amount) external {
        //ok: olympus-dao-staking-incorrect-call-order
        rebase();
        QWA.transferFrom(msg.sender, address(this), _amount);
        sQWA.transfer(_to, _amount);
    }

    /// @notice redeem sQWA for QWA
    /// @param _to address
    /// @param _amount uint
    function unstake(address _to, uint256 _amount, bool _rebase) external {
        if (_rebase) rebase();
        sQWA.transferFrom(msg.sender, address(this), _amount);
        require(
            _amount <= QWA.balanceOf(address(this)),
            "Insufficient QWA balance in contract"
        );
        QWA.transfer(_to, _amount);
    }

    ///@notice Trigger rebase if epoch over
    function rebase() public {
        if (epoch.end <= block.timestamp) {
            sQWA.rebase(epoch.distribute, epoch.number);

            epoch.end = epoch.end + epoch.length;
            epoch.number++;

            if (address(distributor) != address(0)) {
                distributor.distribute();
            }

            uint256 balance = QWA.balanceOf(address(this));
            uint256 staked = sQWA.circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance - staked;
            }
        }
    }
}

contract HATEStaking is Ownable{
    /* ========== EVENTS ========== */

    event DistributorSet(address distributor);

    /* ========== DATA STRUCTURES ========== */

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    struct Claim {
        uint256 deposit; // if forfeiting
        uint256 gons; // staked balance
        uint256 expiry; // end of warmup period
        bool lock; // prevents malicious delays for claim
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable HATE;
    IsHATE public immutable sHATE;

    Epoch public epoch;

    IDistributor public distributor;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _HATE, address _sHATE, uint256 _epochLength) {
        require(_HATE != address(0), "Zero address: HATE");
        HATE = IERC20(_HATE);
        require(_sHATE != address(0), "Zero address: sHATE");
        sHATE = IsHATE(_sHATE);

        epoch = Epoch({length: _epochLength, number: 0, end: block.timestamp + _epochLength, distribute: 0});
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice stake HATE
     * @param _to address
     * @param _amount uint
     */
    function stake(address _to, uint256 _amount) external {
        //ruleid: olympus-dao-staking-incorrect-call-order
        HATE.transferFrom(msg.sender, address(this), _amount);
        rebase();
        sHATE.transfer(_to, _amount);
    }

    /**
     * @notice redeem sHATE for HATEs
     * @param _to address
     * @param _amount uint
     */
    function unstake(address _to, uint256 _amount, bool _rebase) external {
        if (_rebase) rebase();
        sHATE.transferFrom(msg.sender, address(this), _amount);
        require(_amount <= HATE.balanceOf(address(this)), "Insufficient HATE balance in contract");
        HATE.transfer(_to, _amount);
    }

    /**
     * @notice trigger rebase if epoch over
     */
    function rebase() public {
        if (epoch.end <= block.timestamp) {
            sHATE.rebase(epoch.distribute, epoch.number);

            epoch.end = epoch.end + epoch.length;
            epoch.number++;

            if (address(distributor) != address(0)) {
                distributor.distribute();
            }

            uint256 balance = HATE.balanceOf(address(this));
            uint256 staked = sHATE.circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance - staked;
            }
        }
    }
}

contract Staking is Ownable {
    /// EVENTS ///

    event DistributorSet(address distributor);

    /// DATA STRUCTURES ///

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    /// STATE VARIABLES ///

    /// @notice TOKEN address
    IERC20 public immutable TOKEN;
    /// @notice sTOKEN address
    IsStakingProtocol public immutable sTOKEN;

    /// @notice Current epoch details
    Epoch public epoch;

    /// @notice Distributor address
    IDistributor public distributor;

    /// CONSTRUCTOR ///

    /// @param _TOKEN                   Address of TOKEN
    /// @param _sTOKEN                  Address of sTOKEN
    /// @param _epochLength            Epoch length
    /// @param _secondsTillFirstEpoch  Seconds till first epoch starts
    constructor(
        address _TOKEN,
        address _sTOKEN,
        uint256 _epochLength,
        uint256 _secondsTillFirstEpoch
    ) {
        require(_TOKEN != address(0), "Zero address: TOKEN");
        TOKEN = IERC20(_TOKEN);
        require(_sTOKEN != address(0), "Zero address");
        sTOKEN = IsStakingProtocol(_sTOKEN);

        epoch = Epoch({
            length: _epochLength,
            number: 0,
            end: block.timestamp + _secondsTillFirstEpoch,
            distribute: 0
        });
    }

    /// MUTATIVE FUNCTIONS ///

    /// @notice stake TOKEN
    /// @param _to address
    /// @param _amount uint
    function stake(address _to, uint256 _amount) external {
        //ok: olympus-dao-staking-incorrect-call-order
        rebase();
        TOKEN.transferFrom(msg.sender, address(this), _amount);
        sTOKEN.transfer(_to, _amount);
    }

    /// @notice redeem sTOKEN for TOKEN
    /// @param _to address
    /// @param _amount uint
    function unstake(address _to, uint256 _amount, bool _rebase) external {
        if (_rebase) rebase();
        sTOKEN.transferFrom(msg.sender, address(this), _amount);
        require(
            _amount <= TOKEN.balanceOf(address(this)),
            "Insufficient TOKEN balance in contract"
        );
        TOKEN.transfer(_to, _amount);
    }

    ///@notice Trigger rebase if epoch over
    function rebase() public {
        if (epoch.end <= block.timestamp) {
            sTOKEN.rebase(epoch.distribute, epoch.number);

            epoch.end = epoch.end + epoch.length;
            epoch.number++;

            if (address(distributor) != address(0)) {
                distributor.distribute();
            }

            uint256 balance = TOKEN.balanceOf(address(this));
            uint256 staked = sTOKEN.circulatingSupply();

            if (balance <= staked) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance - staked;
            }
        }
    }
}
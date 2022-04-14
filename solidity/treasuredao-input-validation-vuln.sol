// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import '@openzeppelin/contracts/interfaces/IERC165.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';

import './TreasureMarketplace.sol';

contract TreasureMarketplaceBuyer is ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;

    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    TreasureMarketplace public marketplace;

    constructor(address _marketplace) {
        marketplace = TreasureMarketplace(_marketplace);
    }

    function buyItem(
        address _nftAddress,
        uint256 _tokenId,
        address _owner,
        uint256 _quantity,
        uint256 _pricePerItem
    ) external {
        (, uint256 pricePerItem,) = marketplace.listings(_nftAddress, _tokenId, _owner);
        require(_quantity > 0);
        require(pricePerItem == _pricePerItem, "pricePerItem changed!");
        // todoruleid: treasuredao-input-validation-vuln
        uint256 totalPrice =    _pricePerItem *  _quantity;
        IERC20(marketplace.paymentToken()).safeTransferFrom(msg.sender, address(this), totalPrice);
        IERC20(marketplace.paymentToken()).safeApprove(address(marketplace), totalPrice);

        marketplace.buyItem(_nftAddress, _tokenId, _owner, _quantity);

        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
        } else {
            IERC1155(_nftAddress).safeTransferFrom(address(this), msg.sender, _tokenId, _quantity, bytes(""));
        }
    }

    // just in case there's anything stuck here

    function withdraw() external {
        IERC20 token = IERC20(marketplace.paymentToken());
        token.safeTransferFrom(address(this), marketplace.owner(), token.balanceOf(address(this)));
    }

    function withdrawNFT(address _nftAddress, uint256 _tokenId, uint256 _quantity) external {
        if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(_nftAddress).safeTransferFrom(address(this), marketplace.owner(), _tokenId);
        } else {
            IERC1155(_nftAddress).safeTransferFrom(address(this), marketplace.owner(), _tokenId, _quantity, bytes(""));
        }
    }
}

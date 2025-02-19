// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {MockERC721} from "./mocks/MockERC721.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract NFTMarketTest is Test {
    NFTMarket public market;
    MockERC721 public nft;
    MockERC20 public payToken;
    
    address seller = makeAddr("seller");
    address buyer = makeAddr("buyer");
    
    uint256 constant NFT_ID = 1;
    uint256 constant INITIAL_BALANCE = 10000 ether;
    uint256 constant PRICE = 100 ether;

    // 测试前设置
    function setUp() public {
        // 部署合约
        market = new NFTMarket();
        nft = new MockERC721();
        payToken = new MockERC20();

        // 给测试账户铸造NFT和代币
        nft.mint(seller, NFT_ID);
        payToken.mint(buyer, INITIAL_BALANCE);
    }

    // ============ 上架NFT测试 ============

    function test_ListNFT() public {
        // 准备：授权NFT给市场合约
        vm.startPrank(seller);
        nft.approve(address(market), NFT_ID);

        // 期望触发Listed事件
        vm.expectEmit(true, true, true, true);
        emit Listed(0, seller, address(nft), NFT_ID, address(payToken), PRICE);

        // 执行上架
        uint256 listingId = market.listNFT(
            address(nft),
            NFT_ID,
            address(payToken),
            PRICE
        );

        // 验证上架信息
        (
            address _seller,
            address _nftAddress,
            uint256 _tokenId,
            address _payToken,
            uint256 _price,
            bool _isActive
        ) = market.getListing(listingId);

        assertEq(_seller, seller);
        assertEq(_nftAddress, address(nft));
        assertEq(_tokenId, NFT_ID);
        assertEq(_payToken, address(payToken));
        assertEq(_price, PRICE);
        assertTrue(_isActive);

        vm.stopPrank();
    }

    function testFail_ListNFTWithZeroPrice() public {
        vm.startPrank(seller);
        nft.approve(address(market), NFT_ID);
        
        vm.expectRevert("Price must be greater than 0");
        market.listNFT(address(nft), NFT_ID, address(payToken), 0);
        
        vm.stopPrank();
    }

    function testFail_ListNFTWithoutApproval() public {
        vm.startPrank(seller);
        vm.expectRevert("NFT not approved");
        market.listNFT(address(nft), NFT_ID, address(payToken), PRICE);
        vm.stopPrank();
    }

    // ============ 购买NFT测试 ============

    function test_BuyNFT() public {
        // 准备：上架NFT
        vm.startPrank(seller);
        nft.approve(address(market), NFT_ID);
        uint256 listingId = market.listNFT(
            address(nft),
            NFT_ID,
            address(payToken),
            PRICE
        );
        vm.stopPrank();

        // 准备：买家授权代币
        vm.startPrank(buyer);
        payToken.approve(address(market), PRICE);

        // 期望触发Sale事件
        vm.expectEmit(true, true, true, true);
        emit Sale(
            listingId,
            buyer,
            seller,
            address(nft),
            NFT_ID,
            address(payToken),
            PRICE
        );

        // 执行购买
        market.buyNFT(listingId);

        // 验证NFT所有权转移
        assertEq(nft.ownerOf(NFT_ID), buyer);
        // 验证代币转移
        assertEq(payToken.balanceOf(seller), PRICE);
        assertEq(payToken.balanceOf(buyer), INITIAL_BALANCE - PRICE);
        
        vm.stopPrank();
    }

    function testFail_BuyOwnNFT() public {
        // 上架NFT
        vm.startPrank(seller);
        nft.approve(address(market), NFT_ID);
        uint256 listingId = market.listNFT(
            address(nft),
            NFT_ID,
            address(payToken),
            PRICE
        );

        vm.expectRevert("Seller cannot buy");
        market.buyNFT(listingId);
        vm.stopPrank();
    }

    function testFail_BuyNFTTwice() public {
        // 上架NFT
        vm.startPrank(seller);
        nft.approve(address(market), NFT_ID);
        uint256 listingId = market.listNFT(
            address(nft),
            NFT_ID,
            address(payToken),
            PRICE
        );
        vm.stopPrank();

        // 第一次购买
        vm.startPrank(buyer);
        payToken.approve(address(market), PRICE);
        market.buyNFT(listingId);

        // 尝试第二次购买
        vm.expectRevert("Listing is not active");
        market.buyNFT(listingId);
        vm.stopPrank();
    }

    // ============ 模糊测试 ============

    function testFuzz_ListAndBuyNFT(uint256 price) public {
        // 限制价格范围在 0.01-10000 token
        vm.assume(price > 0.01 ether && price < 10000 ether);
        
        // 确保买家有足够余额
        payToken.mint(buyer, price);

        // 上架NFT
        vm.startPrank(seller);
        nft.approve(address(market), NFT_ID);
        uint256 listingId = market.listNFT(
            address(nft),
            NFT_ID,
            address(payToken),
            price
        );
        vm.stopPrank();

        // 购买NFT
        vm.startPrank(buyer);
        payToken.approve(address(market), price);
        market.buyNFT(listingId);
        vm.stopPrank();

        // 验证交易结果
        assertEq(nft.ownerOf(NFT_ID), buyer);
        assertEq(payToken.balanceOf(seller), price);
    }

    // ============ 不变量测试 ============

    function test_MarketBalanceInvariant() public {
        // 上架NFT
        vm.startPrank(seller);
        nft.approve(address(market), NFT_ID);
        uint256 listingId = market.listNFT(
            address(nft),
            NFT_ID,
            address(payToken),
            PRICE
        );
        vm.stopPrank();

        // 记录市场合约初始余额
        uint256 initialBalance = payToken.balanceOf(address(market));

        // 执行购买
        vm.startPrank(buyer);
        payToken.approve(address(market), PRICE);
        market.buyNFT(listingId);
        vm.stopPrank();

        // 验证市场合约余额未变
        assertEq(payToken.balanceOf(address(market)), initialBalance);
    }

    // ============ 事件定义 ============
    
    event Listed(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price
    );

    event Sale(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed seller,
        address nftAddress,
        uint256 tokenId,
        address payToken,
        uint256 price
    );
} 

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;    

// 导入需要使用的外部合约接口
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";    // NFT标准接口
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";      // ERC20代币标准接口
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // 防重入攻击的合约

// NFTMarket合约，继承ReentrancyGuard以防止重入攻击
contract NFTMarket is ReentrancyGuard {
    // 定义上架信息的结构体，用于存储NFT上架的详细信息
    struct Listing {
        address seller;      // 卖家的钱包地址
        address nftAddress;  // NFT合约的地址
        uint256 tokenId;    // NFT的唯一标识ID
        address payToken;    // 用于支付的ERC20代币地址
        uint256 price;      // NFT的售价
        bool isActive;      // 上架状态：true表示正在售卖，false表示已售出或已下架
    }

    // 存储所有上架信息的映射，key是上架ID，value是上架信息
    mapping(uint256 => Listing) public listings;
    uint256 private _listingId;    // 上架ID计数器，每次上架自动增加

    // 定义事件，用于记录重要操作，方便前端监听和查询历史记录
    // indexed关键字用于建立索引，方便快速查询
    event Listed(
        uint256 indexed listingId,  // 上架ID
        address indexed seller,      // 卖家地址
        address indexed nftAddress,  // NFT合约地址
        uint256 tokenId,            // NFT的ID
        address payToken,           // 支付代币地址
        uint256 price              // 价格
    );
    
    // 销售完成事件
    event Sale(
        uint256 indexed listingId,  // 上架ID
        address indexed buyer,       // 买家地址
        address indexed seller,      // 卖家地址
        address nftAddress,         // NFT合约地址
        uint256 tokenId,            // NFT的ID
        address payToken,           // 支付代币地址
        uint256 price              // 成交价格
    );

    // 取消上架事件
    event ListingCanceled(uint256 indexed listingId);

    // 上架NFT的函数
    function listNFT(
        address nftAddress,    // NFT合约地址
        uint256 tokenId,      // NFT的ID
        address payToken,     // 接受支付的代币地址
        uint256 price        // 售价
    ) external nonReentrant returns (uint256) {  // nonReentrant防止重入攻击
        // 检查价格是否大于0
        require(price > 0, "Price must be greater than 0");
        
        // 检查调用者是否是NFT的所有者
        require(
            IERC721(nftAddress).ownerOf(tokenId) == msg.sender,
            "Not NFT owner"
        );
        
        // 检查NFT是否已授权给市场合约
        require(
            IERC721(nftAddress).getApproved(tokenId) == address(this),
            "NFT not approved"
        );

        // 生成新的上架ID
        uint256 listingId = _listingId++;
        
        // 创建新的上架信息并存储
        listings[listingId] = Listing({
            seller: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            payToken: payToken,
            price: price,
            isActive: true
        });

        // 触发上架事件
        emit Listed(
            listingId,
            msg.sender,
            nftAddress,
            tokenId,
            payToken,
            price
        );

        return listingId;  // 返回上架ID
    }

    // 购买NFT的函数
    function buyNFT(uint256 listingId) external nonReentrant {
        // 从存储中获取上架信息
        Listing storage listing = listings[listingId];
        // 检查上架是否有效
        require(listing.isActive, "Listing is not active");
        // 检查买家不是卖家
        require(msg.sender != listing.seller, "Seller cannot buy");

        // 处理代币支付
        IERC20 payToken = IERC20(listing.payToken);
        // 将代币从买家转移给卖家
        require(
            payToken.transferFrom(msg.sender, listing.seller, listing.price),
            "Payment failed"
        );

        // 将NFT转移给买家
        IERC721(listing.nftAddress).safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );

        // 更新上架状态为非活跃
        listing.isActive = false;

        // 触发销售完成事件
        emit Sale(
            listingId,
            msg.sender,
            listing.seller,
            listing.nftAddress,
            listing.tokenId,
            listing.payToken,
            listing.price
        );
    }

    // 取消上架的函数
    function cancelListing(uint256 listingId) external nonReentrant {
        Listing storage listing = listings[listingId];
        // 检查上架是否有效
        require(listing.isActive, "Listing is not active");
        // 检查调用者是否是卖家
        require(msg.sender == listing.seller, "Not the seller");

        // 更新上架状态为非活跃
        listing.isActive = false;
        // 触发取消上架事件
        emit ListingCanceled(listingId);
    }

    // 查询上架信息的函数
    function getListing(uint256 listingId) external view returns (
        address seller,      // 卖家地址
        address nftAddress,  // NFT合约地址
        uint256 tokenId,     // NFT的ID
        address payToken,    // 支付代币地址
        uint256 price,       // 价格
        bool isActive       // 是否有效
    ) {
        // 从存储中读取上架信息
        Listing memory listing = listings[listingId];
        // 返回所有信息
        return (
            listing.seller,
            listing.nftAddress,
            listing.tokenId,
            listing.payToken,
            listing.price,
            listing.isActive
        );
    }
}

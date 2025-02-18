// SPDX-License-Identifier: MIT
// 声明开源协议类型

pragma solidity ^0.8.0;
// 指定Solidity编译器版本

// 导入我们之前创建的NFT和代币合约
import "./ERC721_NFT.sol";
import "./TokenBankV2.sol";

// 定义NFT交易市场合约，实现ITokenReceiver接口以支持直接转账购买
contract NFTMarket is ITokenReceiver {
    // 声明扩展的ERC20代币合约实例
    ExtendedERC20 public token;
    // 声明NFT合约实例
    BaseERC721 public nft;
    
    // 定义NFT上架信息的结构体
    struct Listing {
        address seller;    // 存储卖家地址
        uint256 price;     // 存储NFT售价（以token为单位）
        bool isActive;     // 标记NFT是否处于在售状态
    }
    
    // 使用映射存储每个NFT的上架信息，tokenId => Listing
    mapping(uint256 => Listing) public listings;
    
    // 定义事件，用于记录重要操作
    // indexed关键字用于优化事件过滤
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);    // NFT上架事件
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);  // NFT售出事件
    event NFTDelisted(uint256 indexed tokenId, address indexed seller);  // NFT下架事件
    
    // 构造函数，初始化合约时设置代币和NFT合约地址
    constructor(address _token, address _nft) {
        token = ExtendedERC20(_token);  // 初始化代币合约实例
        nft = BaseERC721(_nft);         // 初始化NFT合约实例
    }
    
    /**
     * @dev 上架NFT功能
     * @param tokenId 要上架的NFT的ID
     * @param price 设置的售价（以token为单位）
     */
    function list(uint256 tokenId, uint256 price) external {
        // 验证调用者是否是NFT的所有者
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        // 验证价格是否大于0
        require(price > 0, "Price must be greater than 0");
        
        // 检查NFT是否已经授权给市场合约
        require(
            nft.getApproved(tokenId) == address(this) || 
            nft.isApprovedForAll(msg.sender, address(this)),
            "NFT not approved for marketplace"
        );
        
        // 创建并存储上架信息
        listings[tokenId] = Listing({
            seller: msg.sender,  // 设置卖家地址
            price: price,        // 设置售价
            isActive: true       // 标记为在售状态
        });
        
        // 触发NFT上架事件
        emit NFTListed(tokenId, msg.sender, price);
    }
    
    /**
     * @dev 普通购买NFT功能
     * @param tokenId 要购买的NFT的ID
     */
    function buyNFT(uint256 tokenId) external {
        // 获取NFT的上架信息
        Listing memory listing = listings[tokenId];
        
        // 验证NFT是否在售
        require(listing.isActive, "NFT not listed for sale");
        // 验证买家不是卖家
        require(msg.sender != listing.seller, "Cannot buy your own NFT");
        
        // 处理代币转账（买家到卖家）
        require(
            token.transferFrom(msg.sender, listing.seller, listing.price),
            "Token transfer failed"
        );
        
        // 转移NFT所有权（卖家到买家）
        nft.transferFrom(listing.seller, msg.sender, tokenId);
        
        // 删除上架信息
        delete listings[tokenId];
        
        // 触发NFT售出事件
        emit NFTSold(tokenId, listing.seller, msg.sender, listing.price);
    }
    
    /**
     * @dev 实现代币接收接口，支持直接转账购买NFT
     * @param from 代币的发送者地址
     * @param amount 收到的代币数量
     */
    function tokensReceived(
        address from,
        uint256 amount
    ) external override returns (bool) {
        // 验证调用者是否是代币合约
        require(msg.sender == address(token), "Invalid token");
        
        // 遍历上架的NFT，寻找价格匹配的第一个NFT
        for (uint256 i = 0; i < 10000; i++) {  // 设置遍历上限，防止gas消耗过大
            Listing memory listing = listings[i];
            // 检查NFT是否在售且价格匹配
            if (listing.isActive && listing.price == amount) {
                // 转移代币给卖家
                require(
                    token.transfer(listing.seller, amount),
                    "Token transfer failed"
                );
                
                // 转移NFT给买家
                nft.transferFrom(listing.seller, from, i);
                
                // 删除上架信息
                delete listings[i];
                
                // 触发NFT售出事件
                emit NFTSold(i, listing.seller, from, amount);
                
                return true;  // 购买成功
            }
        }
        
        // 如果没找到匹配的NFT，回滚交易
        revert("No matching NFT found");
    }
    
    /**
     * @dev 下架NFT功能
     * @param tokenId 要下架的NFT的ID
     */
    function delist(uint256 tokenId) external {
        // 获取NFT的上架信息
        Listing memory listing = listings[tokenId];
        
        // 验证调用者是否是卖家
        require(listing.seller == msg.sender, "Not the seller");
        // 验证NFT是否在售
        require(listing.isActive, "NFT not listed");
        
        // 删除上架信息
        delete listings[tokenId];
        
        // 触发NFT下架事件
        emit NFTDelisted(tokenId, msg.sender);
    }
    
    /**
     * @dev 查询NFT价格功能
     * @param tokenId NFT的ID
     * @return 返回NFT的价格
     */
    function getPrice(uint256 tokenId) external view returns (uint256) {
        // 验证NFT是否在售
        require(listings[tokenId].isActive, "NFT not listed");
        // 返回NFT的价格
        return listings[tokenId].price;
    }
}


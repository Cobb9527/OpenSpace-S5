import { createPublicClient, http } from "viem";
import { mainnet } from "viem/chains";

// NFT 合约的 ABI
const nftABI = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "ownerOf",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "tokenURI",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

// 创建公共客户端
const client = createPublicClient({
  chain: mainnet,
  transport: http(),
});

// NFT 合约地址
const NFT_CONTRACT_ADDRESS = "0x0483b0dfc6c78062b9e999a82ffb795925381415";

async function getNFTInfo(tokenId: number) {
  try {
    // 读取 NFT 持有人地址
    const owner = await client.readContract({
      address: NFT_CONTRACT_ADDRESS,
      abi: nftABI,
      functionName: "ownerOf",
      args: [BigInt(tokenId)],
    });

    // 读取 NFT 元数据 URI
    const tokenURI = await client.readContract({
      address: NFT_CONTRACT_ADDRESS,
      abi: nftABI,
      functionName: "tokenURI",
      args: [BigInt(tokenId)],
    });

    return {
      tokenId,
      owner,
      tokenURI,
    };
  } catch (error) {
    console.error("Error fetching NFT info:", error);
    throw error;
  }
}

// 使用示例
async function main() {
  try {
    // 读取 tokenId 为 1 的 NFT 信息
    const nftInfo = await getNFTInfo(1);
    console.log("NFT Info:", nftInfo);
  } catch (error) {
    console.error("Error in main:", error);
  }
}

main();

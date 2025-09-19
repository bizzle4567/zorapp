import { useSigner } from "wagmi";
import { ethers } from "ethers";
import ZoraFactoryImplAbi from "../../coins/abis/ZoraFactoryImpl.json";

"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { getCoin, getCoinsLastTraded, getCoinsMostValuable, getCoinsNew, setApiKey } from "@zoralabs/coins-sdk";
import { formatEther } from "viem";
import { baseSepolia } from "viem/chains";
import { useAccount } from "wagmi";

setApiKey(process.env.NEXT_PUBLIC_ZORA_API_KEY || "");

// Optional kill-switch for media fetching if networks are flaky
const DISABLE_MEDIA_FETCH =
  typeof process !== "undefined" && process.env.NEXT_PUBLIC_DISABLE_MEDIA_FETCH === "true";

async function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort("timeout"), ms);
  try {
    const result = await promise;
    return result;
  } finally {
    clearTimeout(timeout);
  }
}

interface CoinNode {
  id: string;
  name: string;
  symbol: string;
  address: string;
  creatorAddress: string;
  totalSupply: string;
  marketCap: string;
  volume24h: string;
  createdAt: string;
  uniqueHolders: string;
  description?: string;
  totalVolume?: string;
  uniswapV3PoolAddress?: string;
  mediaContent?: {
    previewImage?: {
      small?: string;
      medium?: string;
      large?: string;
    };
  };
}

interface ExploreListResponse {
  data?: {
    exploreList?: {
      edges: { node: CoinNode; cursor: string }[];
      pageInfo: {
        endCursor: string;
        hasNextPage: boolean;
      };
    };
  };
}

type FetchFn = () => Promise<ExploreListResponse>;

interface ExploreTab {
  id: string;
  label: string;
  fetchFunction: FetchFn;
}

function safeFormatEther(wei: string | undefined): string {
  if (!wei) return "0";
  try {
    return formatEther(BigInt(wei));
  } catch {
    return "0";
  }
}

function getRelativeTime(dateString: string): string {
  if (!dateString) return "Unknown";

  const now = new Date();
  const date = new Date(dateString);
  const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

  if (diffInSeconds < 60) {
    return `${diffInSeconds}s ago`;
  } else if (diffInSeconds < 3600) {
    const minutes = Math.floor(diffInSeconds / 60);
    return `${minutes}m ago`;
  } else if (diffInSeconds < 86400) {
    const hours = Math.floor(diffInSeconds / 3600);
    return `${hours}h ago`;
  } else {
    const days = Math.floor(diffInSeconds / 86400);
    return `${days}d ago`;
  }
}

export default function ExplorePage() {
  // Fetch platform-created coins/posts from factory contract events
  useEffect(() => {
    async function fetchPlatformCoins() {
      // Replace with your deployed factory contract address
      const factoryAddress = "0xYourFactoryAddressHere";
      const provider = new ethers.providers.JsonRpcProvider(process.env.NEXT_PUBLIC_RPC_URL);
      const contract = new ethers.Contract(factoryAddress, ZoraFactoryImplAbi, provider);
      // Query CoinCreated events
      const filter = contract.filters.CoinCreated();
      const events = await contract.queryFilter(filter, 0, "latest");
      const coins = events.map(e => ({
        address: e.args.coin,
        name: e.args.name,
        symbol: e.args.symbol,
        uri: e.args.uri,
        creator: e.args.caller,
      }));
      setCoins(coins);
    }
    fetchPlatformCoins();
  }, []);
  {/* Display platform-created coins/posts */}
  <div style={{ margin: "2rem 0" }}>
    <h2>Platform Coins/Posts</h2>
    {coins.length === 0 ? (
      <p>No coins/posts found.</p>
    ) : (
      <ul>
        {coins.map((c, idx) => (
          <li key={c.address} style={{ marginBottom: "1rem" }}>
            <Link href={`/post/${c.address}`} style={{ textDecoration: "none", color: "inherit" }}>
              <strong>{c.name} ({c.symbol})</strong><br />
              Address: {c.address}<br />
              Creator: {c.creator}<br />
              Metadata URI: {c.uri}
            </Link>
          </li>
        ))}
      </ul>
    )}
  </div>
  // Form state for coin/post creation
  const [form, setForm] = useState({
    payoutRecipient: "",
    owners: "",
    uri: "",
    name: "",
    symbol: "",
    platformReferrer: "",
    currency: "",
    int24Param: "0",
    uint256Param: "0",
  });

  function handleFormChange(e: React.ChangeEvent<HTMLInputElement>) {
    const { name, value } = e.target;
    setForm(prev => ({ ...prev, [name]: value }));
  }

  function handleFormSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    // Convert owners from comma-separated string to array
    const ownersArr = form.owners.split(",").map(addr => addr.trim()).filter(Boolean);
    handleDeployCoin({
      payoutRecipient: form.payoutRecipient,
      owners: ownersArr,
      uri: form.uri,
      name: form.name,
      symbol: form.symbol,
      platformReferrer: form.platformReferrer,
      currency: form.currency,
      int24Param: parseInt(form.int24Param, 10),
      uint256Param: ethers.BigNumber.from(form.uint256Param || "0"),
    });
  }

  interface DeployCoinParams {
    payoutRecipient: string;
    owners: string[];
    uri: string;
    name: string;
    symbol: string;
    platformReferrer: string;
    currency: string;
    int24Param: number;
    uint256Param: ethers.BigNumber;
  }

  const ZORA_FACTORY_IMPL_ADDRESS = "0xYourFactoryAddressHere";
  const { data: signer } = useSigner();
  const [deploying, setDeploying] = useState<boolean>(false);

  async function handleDeployCoin({
    payoutRecipient,
    owners,
    uri,
    name,
    symbol,
    platformReferrer,
    currency,
    int24Param,
    uint256Param,
  }: DeployCoinParams): Promise<void> {
    if (!signer) {
      alert("Connect your wallet first.");
      return;
    }
    setDeploying(true);
    try {
      const contract = new ethers.Contract(
        ZORA_FACTORY_IMPL_ADDRESS,
        ZoraFactoryImplAbi,
        signer
      );
      const tx = await contract.deploy(
        payoutRecipient,
        owners,
        uri,
        name,
        symbol,
        platformReferrer,
        currency,
        int24Param,
        uint256Param,
        { value: ethers.utils.parseEther("0") }
      );
      await tx.wait();
      alert("Coin/Post deployed successfully!");
    } catch (err) {
      console.error("Deployment error:", err);
      alert("Deployment failed.");
    }
    setDeploying(false);
  }
  // --- UI Form for Coin/Post Creation ---
  return (
    <>
      {/* ...existing Explore page UI... */}
      <form onSubmit={handleFormSubmit} style={{ margin: "2rem 0", padding: "1rem", border: "1px solid #eee", borderRadius: "8px" }}>
        <h2>Create Coin/Post</h2>
        <input name="payoutRecipient" value={form.payoutRecipient} onChange={handleFormChange} placeholder="Payout Recipient Address" required style={{ display: "block", marginBottom: "8px" }} />
        <input name="owners" value={form.owners} onChange={handleFormChange} placeholder="Owners (comma-separated)" required style={{ display: "block", marginBottom: "8px" }} />
        <input name="uri" value={form.uri} onChange={handleFormChange} placeholder="Metadata URI" required style={{ display: "block", marginBottom: "8px" }} />
        <input name="name" value={form.name} onChange={handleFormChange} placeholder="Name" required style={{ display: "block", marginBottom: "8px" }} />
        <input name="symbol" value={form.symbol} onChange={handleFormChange} placeholder="Symbol" required style={{ display: "block", marginBottom: "8px" }} />
        <input name="platformReferrer" value={form.platformReferrer} onChange={handleFormChange} placeholder="Platform Referrer Address" required style={{ display: "block", marginBottom: "8px" }} />
        <input name="currency" value={form.currency} onChange={handleFormChange} placeholder="Currency Address" required style={{ display: "block", marginBottom: "8px" }} />
        <input name="int24Param" value={form.int24Param} onChange={handleFormChange} placeholder="int24 Param" required style={{ display: "block", marginBottom: "8px" }} />
        <input name="uint256Param" value={form.uint256Param} onChange={handleFormChange} placeholder="uint256 Param" required style={{ display: "block", marginBottom: "8px" }} />
        <button type="submit" disabled={deploying} style={{ padding: "0.5rem 1rem" }}>
          {deploying ? "Deploying..." : "Deploy Coin/Post"}
        </button>
      </form>
      {/* ...existing Explore page UI... */}
    </>
  );
  // (Removed duplicate contract logic and state declarations)

  // Example usage: call handleDeployCoin with user-supplied values when form is submitted
  // handleDeployCoin({ payoutRecipient, owners, uri, name, symbol, platformReferrer, currency, int24Param, uint256Param });
  const { address } = useAccount();
  const [coins, setCoins] = useState<CoinNode[]>([]);
  const [coinMetasLoading, setCoinMetasLoading] = useState(false);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<ExploreTab["id"]>("new");

  const exploreTabs: ExploreTab[] = useMemo(
    () => [
      {
        id: "new",
        label: "🆕 New Coins",
        fetchFunction: () => getCoinsNew({ count: 200 }) as Promise<ExploreListResponse>,
      },
      {
        id: "valuable",
        label: "💎 High Marketcap",
        fetchFunction: () => getCoinsMostValuable({ count: 20 }) as Promise<ExploreListResponse>,
      },
      {
        id: "trending",
        label: "🔥 Recently Traded",
        fetchFunction: () => getCoinsLastTraded({ count: 20 }) as Promise<ExploreListResponse>,
      },
    ],
    [],
  );

  const fetchCoins = useCallback(async () => {
    setLoading(true);
    const tab = exploreTabs.find(t => t.id === activeTab);
    if (!tab) return setLoading(false);

    try {
      const res = await tab.fetchFunction();
      const edges = res.data?.exploreList?.edges || [];
      setCoins(
        edges.map(({ node }) => ({
          ...node,
          totalSupply: safeFormatEther(node.totalSupply),
          marketCap: safeFormatEther(node.marketCap),
          volume24h: safeFormatEther(node.volume24h),
        })),
      );
    } catch (err) {
      console.error("Error fetching coins:", err);
      console.error("Failed to fetch coins. Please try again.");
      setCoins([]);
    } finally {
      setLoading(false);
    }
  }, [activeTab, exploreTabs]);

  useEffect(() => {
    fetchCoins();
  }, [fetchCoins]);

  useEffect(() => {
    if (!coins.length) return;
    // If no API key or explicitly disabled, skip extra media fetches
    if (!process.env.NEXT_PUBLIC_ZORA_API_KEY || DISABLE_MEDIA_FETCH) return;
    let cancelled = false;
    async function fetchAllCoinsWithMedia() {
      setCoinMetasLoading(true);
      // Process in small batches to avoid flooding the API/browser with requests
      const chunkSize = 6;
      const chunks: typeof coins[] = [];
      for (let i = 0; i < coins.length; i += chunkSize) {
        chunks.push(coins.slice(i, i + chunkSize));
      }
      const results: typeof coins = [];
      for (const group of chunks) {
        const settled = await Promise.allSettled(
          group.map(async c => {
            try {
              const response = await withTimeout(
                getCoin({ address: c.address, chain: baseSepolia.id }),
                8000,
              );
            const fullCoin = response.data?.zora20Token;
            if (fullCoin && fullCoin.mediaContent) {
                return { ...c, mediaContent: fullCoin.mediaContent } as typeof c;
            }
            return c;
          } catch (err) {
            console.error(`Failed to fetch full coin data for ${c.address}:`, err);
            return c;
          }
        }),
      );
        for (const r of settled) {
          results.push(r.status === "fulfilled" ? r.value : group[results.length % group.length]);
        }
        if (cancelled) break;
      }
      const updatedCoins = cancelled ? coins : results;
      if (!cancelled) {
        setCoins(updatedCoins);
        setCoinMetasLoading(false);
      }
    }
    fetchAllCoinsWithMedia();
    return () => {
      cancelled = true;
    };
  }, [coins.length, coins]);

  if (loading) {
    return (
      <div className="flex justify-center items-center min-h-screen">
        <div className="flex flex-col items-center gap-4">
          <span className="loading loading-spinner loading-lg" />
          <p>Loading coins...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Top bar with a "search" input like TikTok's */}
      <div className="flex items-center gap-2 mb-8">
        <div className="relative flex-grow">
          <input
            type="text"
            placeholder="Search coins..."
            className="w-full pl-10 pr-4 py-2 rounded-full border border-base-300 bg-base-200 focus:outline-none focus:ring-2 focus:ring-primary"
          />
          <svg
            className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden
          >
            <path
              d="M21 21l-4.35-4.35m2.02-5.15a7.5 7.5 0 11-15 0 7.5 7.5 0 0115 0z"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </div>
      </div>

      {/* Horizontally scrollable tabs */}
      <div className="flex overflow-x-auto gap-2 p-2 mb-8 scrollbar-hide">
              {exploreTabs.map(tab => (
                <button
                  key={tab.id}
            className={`btn btn-sm rounded-full ${activeTab === tab.id ? "btn-primary" : "btn-ghost"}`}
                  onClick={() => setActiveTab(tab.id)}
                >
                  {tab.label}
                </button>
              ))}
        </div>

          {coins.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-xl opacity-70">No coins found</p>
              <p className="text-sm opacity-50">Try a different category or check back later</p>
            </div>
          ) : (
        /* The main grid of cards, now visually immersive */
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-2">
          {coins.map(c => {
              const mediaUrl = c.mediaContent?.previewImage?.medium || c.mediaContent?.previewImage?.small || null;
              return (
              <Link href={`/post/${c.address}`} key={c.id}>
                {/* The card as a link for a seamless experience */}
                <div className="relative w-full aspect-[9/16] rounded-lg overflow-hidden cursor-pointer group">
                  {/* Media (Image) as the background */}
                      {coinMetasLoading ? (
                    <div className="w-full h-full animate-pulse bg-base-200" />
                      ) : mediaUrl ? (
                        <Image
                          src={mediaUrl}
                          alt={c.name}
                          width={400}
                      height={400}
                      className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                          onError={(e: React.SyntheticEvent<HTMLImageElement, Event>) => {
                            (e.target as HTMLImageElement).style.display = "none";
                          }}
                        />
                      ) : (
                    <div className="w-full h-full flex items-center justify-center bg-base-200 opacity-50">
                          <span className="text-xs">No media</span>
                        </div>
                      )}

                  {/* Overlay for text and creator info */}
                  <div className="absolute inset-x-0 bottom-0 p-3 text-white bg-gradient-to-t from-black/80 to-transparent">
                    {/* Coin name and symbol */}
                    <div className="flex items-center mb-1">
                      <h2 className="text-sm md:text-base font-semibold truncate leading-tight">{c.name}</h2>
                      <span className="text-xs opacity-70 ml-1">({c.symbol})</span>
                    </div>

                    {/* Creator avatar and address */}
                    <div className="flex items-center gap-1">
                      <Image
                        src={`https://api.dicebear.com/7.x/identicon/svg?seed=${c.creatorAddress}`}
                        alt="avatar"
                        width={18}
                        height={18}
                        className="rounded-full border border-white/50"
                      />
                      <span className="text-xs font-mono opacity-70 truncate">
                        {c.creatorAddress.slice(0, 4)}...{c.creatorAddress.slice(-4)}
                      </span>
                    </div>
                  </div>
                </div>
              </Link>
              );
            })}
        </div>
      )}

      {!address && (
        <div className="alert alert-info mt-8">
          <span>💡 Connect your wallet to trade coins and support creators</span>
        </div>
      )}
    </div>
  );
}
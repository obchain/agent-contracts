// SPDX-License-Identifier: BUSL-1.1

// ███╗   ███╗ █████╗ ██╗  ██╗ █████╗
// ████╗ ████║██╔══██╗██║  ██║██╔══██╗
// ██╔████╔██║███████║███████║███████║
// ██║╚██╔╝██║██╔══██║██╔══██║██╔══██║
// ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██║
// ╚═╝    ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

// Website: https://maha.xyz
// Discord: https://discord.gg/mahadao
// Twitter: https://twitter.com/mahaxyz_

pragma solidity ^0.8.0;

import {IAeroPool} from "../interfaces/IAeroPool.sol";
import {IAgentToken} from "../interfaces/IAgentToken.sol";
import {AgentLaunchpadBase} from "./AgentLaunchpadBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract AgentLaunchpadLocker is AgentLaunchpadBase {
  function _lockTokens(IAgentToken token, uint256 amount) internal {
    uint256 duration = token.expiry() - block.timestamp;
    require(amount > 0, "Amount must be greater than 0");
    require(duration > 0, "Duration must be greater than 0");
    require(tokenLocks[address(token)].amount == 0, "lock exists");

    tokenLocks[address(token)] = TokenLock({amount: amount, startTime: block.timestamp, duration: duration});
    // todo add event
  }

  function _lockLiquidity(IAgentToken token, address pool) internal {
    require(liquidityLocks[address(token)].amount == 0, "lock exists");
    liquidityLocks[address(token)] = LiquidityLock({
      liquidityToken: IAeroPool(pool),
      amount: IERC20(pool).balanceOf(address(this)),
      releaseTime: token.expiry()
    });
    // todo add event
  }

  function releaseTokens() external {
    TokenLock storage lock = tokenLocks[msg.sender];
    require(lock.amount > 0, "No tokens locked");

    uint256 elapsedTime = block.timestamp - lock.startTime;
    uint256 releasableAmount = (lock.amount * elapsedTime) / lock.duration;

    if (elapsedTime >= lock.duration) releasableAmount = lock.amount;

    require(releasableAmount > 0, "No tokens to release");

    lock.amount -= releasableAmount;
    IERC20(msg.sender).transfer(msg.sender, releasableAmount);

    if (lock.amount == 0) delete tokenLocks[msg.sender];
    // todo add event
  }

  function releaseLiquidityLock() external {
    LiquidityLock storage lock = liquidityLocks[msg.sender];
    require(lock.amount != 0, "No lock locked");
    require(block.timestamp >= lock.releaseTime, "Liquidity is still locked");

    uint256 tokenId = lock.amount;
    delete liquidityLocks[msg.sender];

    IERC721(address(aeroFactory)).transferFrom(address(this), msg.sender, tokenId);
    // todo add event
  }

  function claimFees(address token) external {
    IERC20 fundingToken = IERC20(fundingTokens[IAgentToken(token)]);

    // if funding token is the core token; then no fees get charged. else the feeCutE18 is applied
    uint256 _feeCutE18 = fundingToken == coreToken ? 0 : feeCutE18;

    LiquidityLock storage lock = liquidityLocks[token];
    require(lock.amount != 0, "No lock locked");

    address dest = ownerOf(tokenToNftId[IAgentToken(token)]);

    IAeroPool pool = lock.liquidityToken;
    (uint256 fee0, uint256 fee1) = pool.claimFees();

    uint256 govFee0 = fee0 * _feeCutE18 / 1e18;
    uint256 govFee1 = fee1 * _feeCutE18 / 1e18;

    IERC20(pool.token0()).transfer(dest, fee0 - govFee0);
    IERC20(pool.token1()).transfer(dest, fee1 - govFee1);

    IERC20(pool.token0()).transfer(feeDestination, govFee0);
    IERC20(pool.token1()).transfer(feeDestination, govFee1);
    // todo add event
  }
}

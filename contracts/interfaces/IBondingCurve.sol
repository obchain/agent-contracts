// SPDX-License-Identifier: BUSL-1.1

// ███╗   ███╗ █████╗ ██╗  ██╗ █████╗
// ████╗ ████║██╔══██╗██║  ██║██╔══██╗
// ██╔████╔██║███████║███████║███████║
// ██║╚██╔╝██║██╔══██║██╔══██║██╔══██║
// ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

// Website: https://maha.xyz
// Discord: https://discord.gg/mahadao
// Twitter: https://twitter.com/mahaxyz_

pragma solidity ^0.8.0;

interface IBondingCurve {
  function calculateBuy(uint256 quantityIn, uint256 raisedAmount, uint256 totalRaise)
    external
    view
    returns (uint256 _tokensOut, uint256 _assetsIn, uint256 _priceE18);

  function calculateSell(uint256 quantityOut, uint256 raisedAmount, uint256 totalRaise)
    external
    view
    returns (uint256 _amountOut, uint256 _amountIn, uint256 _priceE18);
}

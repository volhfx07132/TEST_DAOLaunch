pragma solidity ^0.8.0;
//Lock liquidity provice token; 
interface IUniswapV2Locker {
    function lockLPToken(address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _referral, bool _fee_in_eth, address payable _withdraw) external; 
}
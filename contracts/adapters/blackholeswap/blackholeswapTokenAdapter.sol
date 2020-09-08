// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import { ERC20 } from "../../ERC20.sol";
import { TokenMetadata, Component } from "../../Structs.sol";
import { TokenAdapter } from "../TokenAdapter.sol";

/**
 * @dev BlackHoleSwapRegistry contract interface.
 * Only the functions required for BlackHoleSwapTokenAdapter contract are added.
 * The BlackHoleSwapRegistry contract is available here
 * github.com/zeriontech/defi-sdk/blob/master/contracts/adapters/blackholeswap/BlackHoleSwapRegistry.sol.
 */
interface BlackHoleSwapRegistry {
    function getToken0(address) external view returns (address);
    function getToken1(address) external view returns (address);
    function getName(address) external view returns (string memory);
}


/**
 * @dev blackholeswap contract interface.
 * Only the functions required for BlackHoleSwapTokenAdapter contract are added.
 * The blackholeswap contract is available here
 * github.com/XXXXXXXX
 */
interface CToken {
    function exchangeRateStored() external view returns (uint256);
    function borrowBalanceStored(address) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

/**
 * @title Token adapter for blackholeswap pool tokens.
 * @dev Implementation of TokenAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract BlackHoleSwapTokenAdapter is TokenAdapter {

    address internal constant REGISTRY = 0x1e92dCc1707ddCc6bE438A3187Da2f6493cEE58A;
    address internal constant CDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address internal constant CUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;

    /**
     * @return TokenMetadata struct with ERC20-style token info.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getMetadata(address token) external view override returns (TokenMetadata memory) {
        return TokenMetadata({
            token: token,
            name: getPoolName(token),
            symbol: getSymbol(token),
            decimals: ERC20(token).decimals()
        });
    }
    
    /**
     * @return Array of Component structs with underlying tokens rates for the given token.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        address[] memory tokens = new address[](2);
        tokens[0] = BlackHoleSwapRegistry(REGISTRY).getToken0(token);
        tokens[1] = BlackHoleSwapRegistry(REGISTRY).getToken1(token);

        Component[] memory underlyingTokens = new Component[](2);

        for (uint256 i = 0; i < 2; i++) {
            underlyingTokens[i] = Component({
                token: tokens[i],
                tokenType: getTokenType(tokens[i]),
                rate: getTokenRate(token, tokens[i])
            });
        }

        return underlyingTokens;
    }

    function getTokenBalanceOf(address poolToken, address token) internal view returns (uint256, uint256) {
        if (token == CDAI) {
            return getDaiBalance(poolToken);
        } else if (token == CUSDC) {
            return getUSDCBalance(poolToken);
        } else {
            return (0, 0);
        }
    }
    
    function getDaiBalance(address token) internal view returns (uint256, uint256) {
        if (CToken(CDAI).balanceOf(token) <= 10) {
            return (0, CToken(CDAI).borrowBalanceStored(token));
        } else {
            return (CToken(CDAI).balanceOf(token) * CToken(CDAI).exchangeRateStored() / 1e18, CToken(CDAI).borrowBalanceStored(token));
        }        
    }
    
    function getUSDCBalance(address token) internal view returns (uint256, uint256) {
        if (CToken(CUSDC).balanceOf(token) <= 10) {
            return (0, CToken(CUSDC).borrowBalanceStored(token) * 1e12);
        } else {
            return (CToken(CUSDC).balanceOf(token) * CToken(CUSDC).exchangeRateStored() / 1e18  * 1e12, CToken(CUSDC).borrowBalanceStored(token)  * 1e12);
        }        
    }

    function getTokenRate(address poolToken, address token) internal view returns (uint256) {
        (uint256 balanceOfUnderlying, uint256 borrowBalanceCurrent) = getTokenBalanceOf(poolToken, token);
        if (balanceOfUnderlying > borrowBalanceCurrent) {
            return (balanceOfUnderlying - borrowBalanceCurrent) * 1e18 / ERC20(poolToken).totalSupply();
        } else {
            return -((borrowBalanceCurrent - balanceOfUnderlying) * 1e18 / ERC20(poolToken).totalSupply());
        }
    }

    function getPoolName(address token) internal view returns (string memory) {
        return BlackHoleSwapRegistry(REGISTRY).getName(token);
    }

    function getSymbol(address token) internal view returns (string memory) {
       return ERC20(token).symbol();
    }

    function getTokenType(address token) internal pure returns (string memory) {
       if (token == CDAI || token == CUSDC) {
            return "CToken";
        } else {
            return "ERC20";
        }
    }
}
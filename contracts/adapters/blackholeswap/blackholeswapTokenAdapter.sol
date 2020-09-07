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
 * @title Token adapter for blackholeswap pool tokens.
 * @dev Implementation of TokenAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract blackholeswapTokenAdapter is TokenAdapter {

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
        tokens[0] = "0x39aa39c021dfbae8fac545936693ac917d5e7563";
        tokens[1] = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
        uint256 totalSupply = ERC20(token).totalSupply();
        Component[] memory underlyingTokens = new Component[](2);

        for (uint256 i = 0; i < 2; i++) {
            underlyingTokens[i] = Component({
                token: tokens[i],
                tokenType: getTokenType(tokens[i]),
                rate: ERC20(tokens[i]).balanceOf(token) * 1e18 / totalSupply
            });
        }

        return underlyingTokens;
    }

    function getPoolName(address token) internal view returns (string memory) {
        return ERC20(token).name();
    }

    function getSymbol(address token) internal view returns (string memory) {
       return ERC20(token).symbol();
    }

    function getTokenType(address token) internal view returns (string memory) {
        (bool success, bytes memory returnData) = token.staticcall{gas: 2000}(
            abi.encodeWithSelector(CToken(token).isCToken.selector)
        );

        if (success) {
            if (returnData.length == 32) {
                return abi.decode(returnData, (bool)) ? "CToken" : "ERC20";
            } else {
                return "ERC20";
            }
        } else {
            return "ERC20";
        }
    }
}
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
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.5;

import { Ownable } from "../../Ownable.sol";


struct PoolInfo {
    address token0;       // token0 address.
    address token1;       // token1 address.
    string name;        // Pool name ("... Pool").
}

/**
 * @title Registry for BlackHoleSwap contracts.
 * @dev Implements two getters - getSwapAndTotalCoins(address) and getName(address).
 * @notice Call getSwapAndTotalCoins(token) and getName(address) function and get address,
 * coins number, and name of stableswap contract for the given token address.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract BlackHoleSwapRegistry is Ownable {

    mapping (address => PoolInfo) internal poolInfo;

    constructor() public {
        poolInfo[0x35101c731b1548B5e48bb23F99eDBc2f5c341935] = PoolInfo({
            token0: 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643,
            token1: 0x39AA39c021dfbaE8faC545936693aC917d5E7563,
            name: "BlackHoleSwap-Compound DAI/USDC v1 (BHSc$)"
        });
    }

    function setPoolInfo(
        address token,
        address token0,
        address token1,
        string calldata name
    )
        external
        onlyOwner
    {
        poolInfo[token] = PoolInfo({
            token0: token0,
            token1: token1,
            name: name
        });
    }

    function getToken0(address token) external view returns (address) {
        return poolInfo[token].token0;
    }

    function getToken1(address token) external view returns (address) {
        return poolInfo[token].token1;
    }

    function getName(address token) external view returns (string memory) {
        return poolInfo[token].name;
    }
}
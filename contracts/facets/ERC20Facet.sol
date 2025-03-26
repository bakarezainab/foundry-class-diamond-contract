// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibAppStorage } from "../libraries/AppStorage.sol";

contract ERC20 {
    LibAppStorage.AppStorage internal s;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Minted(address indexed to, uint256 value);

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
        s.name = name_;
        s.symbol = symbol_;
        s.decimals = decimals_;
        s.totalSupply = totalSupply_;
        s.balances[msg.sender] = totalSupply_;
        s.owner = msg.sender;
    }

    function name() public view returns (string memory) {
        return s.name;
    }

    function symbol() public view returns (string memory) {
        return s.symbol;
    }

    function decimals() public view returns (uint8) {
        return s.decimals;
    }

    function totalSupply() public view returns (uint256) {
        return s.totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0), "ERC20: address zero is not a valid owner");
        return s.balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return s.allowance[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        s.allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = s.balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            s.balances[from] = fromBalance - amount;
            s.balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                s.allowance[owner][spender] = currentAllowance - amount;
            }
        }
    }

    function mint(address to, uint256 amount) public returns (bool) {
        require(msg.sender == s.owner, "ERC20: must be owner");
        require(to != address(0), "ERC20: mint to the zero address");
        require(amount > 0, "ERC20: mint amount must be positive");

        s.totalSupply += amount;
        s.balances[to] += amount;
        emit Transfer(address(0), to, amount);
        emit Minted(to, amount);

        return true;
    }
}
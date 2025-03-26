// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibAppStorage } from "../libraries/AppStorage.sol";

contract ERC20 {

    LibAppStorage.AppStorage internal s;
    
    // string public name;
    // string public symbol;
    // uint8 public decimals;
    // uint256 public totalSupply;
    // address public owner;

    // mapping(address => uint256) public balances;
    // mapping(address => mapping(address => uint256)) public allowances;

    error InvalidAddress();
    error InsufficientFunds();
    error InsufficientAllowance();
    error OnlyOwnerAllowed();
    error InvalidAmount();

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Minted(address indexed _to, uint256 _value);

    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {

        s.name = name_; 
        s.symbol = symbol_;
        s.decimals = decimals_;
        s.totalSupply = totalSupply_;
        s.balances[msg.sender] = totalSupply_;
        s.owner = msg.sender;
               
        
        }

    modifier onlyOwner() {
        if(msg.sender != s.owner) revert OnlyOwnerAllowed();
        _;
    }

    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        if(_owner == address(0)) revert InvalidAddress();
        balance = s.balances[_owner];
        

    }   

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if(_to == address(0)) revert InvalidAddress();
        if(_value > s.balances[msg.sender]) revert InsufficientFunds();

        s.balances[msg.sender] -= _value;
        s.balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        success = true;        
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if(msg.sender == address(0)) revert InvalidAddress();
        if(_to == address(0)) revert InvalidAddress();
        if(_from == address(0)) revert InvalidAddress();
        if(_value > s.balances[_from]) revert InsufficientFunds();
        if(s.allowance[_from][msg.sender] >= _value){
            s.balances[_from] -= _value;
            s.allowance[_from][msg.sender] -= _value;
            s.balances[_to] += _value;

            emit Transfer(_from, _to, _value);
            success = true;
        } else {
            revert InsufficientAllowance();
        }
        }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if(_spender == address(0)) revert InvalidAddress();
        if(s.balances[msg.sender] < _value) revert InsufficientFunds();
        s.allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        remaining = s.allowance[_owner][_spender];
    }

    function mint(address _to, uint256 _value) public onlyOwner returns (bool success) {
        if(_to == address(0)) revert InvalidAddress();
        if(_value <= 0) revert InvalidAmount();

        s.totalSupply += _value;
        s.balances[_to] += _value;

        success = true;
    }
    
}
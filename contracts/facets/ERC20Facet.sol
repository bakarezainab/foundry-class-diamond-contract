// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "../libraries/AppStorage.sol";

contract ERC20 {

    AppStorage internal s;
    
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

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Minted(address indexed _to, uint256 _value);

    constructor (string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {

        s.name =_name; 
        s.symbol = _symbol;
        s.decimals = _decimals;
        s.totalSupply = _totalSupply;
               
        
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
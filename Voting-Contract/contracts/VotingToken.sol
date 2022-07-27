// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "hardhat/console.sol";

//ERC20 Interface
 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
 //Actual token contract
 
contract VotingToken is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public _totalSupply;
    uint256 public _currentPriceInWei;
    uint256 private _currentAmountOfTokens;
    uint256 public _endOfVoting;

    string private _name;
    string private _symbol;

    bool public votingEnded = true;
 
    constructor(string memory name_, string memory symbol_, uint256 currentPriceInWei_) {
        _name = name_;
        _symbol = symbol_;
        _currentPriceInWei = currentPriceInWei_;
    }

    error TooEarly(uint256 time);
    error TooLate(uint256 time);

    modifier onlyBefore(uint256 _time) {
        if (block.timestamp >= _time) revert TooLate(_time);
        _;
    }

     modifier onlyAfter(uint256 _time) {
        if (block.timestamp <= _time) revert TooEarly(_time);
        _;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
 
     function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
 
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
 
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function buy() external payable {
        require(msg.value > 0, "Value cannot be 0.");

        uint256 countOfTokens = msg.value / _currentPriceInWei;
        _totalSupply += countOfTokens;
        _balances[msg.sender] += countOfTokens;
    }

    function sell() external payable {
        require(msg.value > 0, "Value cannot be 0.");

        uint256 countOfTokens = msg.value / _currentPriceInWei;
        _totalSupply -= countOfTokens;
        _balances[msg.sender] -= countOfTokens;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function startVoting (uint256 endOfVoting_) external returns(bool) {
        require(balanceOf(msg.sender) >= (_totalSupply / 1000) * 5, "Not enough ERC20 tokens");

        require(endOfVoting_ > block.timestamp, "Voting smaller than block timestamp");

        require(votingEnded == true, "Voting is already started");

        _endOfVoting = endOfVoting_;
        votingEnded = false;
        emit VotingStarted();
        return true;
    }

    function vote(uint256 _newPrice) external onlyBefore(_endOfVoting) {
        if (balanceOf(msg.sender) >= _currentAmountOfTokens) {
            _currentPriceInWei = _newPrice;
            _currentAmountOfTokens = balanceOf(msg.sender);
        }
    }

    function endVoting() external onlyAfter(_endOfVoting) returns(bool) {
        votingEnded = true;
        _currentAmountOfTokens = 0;
        return true;
    }

     function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    event VotingStarted();
}

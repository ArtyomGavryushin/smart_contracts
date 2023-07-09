// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20 is IERC20{
    uint totalTokens;
    address owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances; // для хранения инфы, что с 1 кошелька можно списать определенное число токенов
    string _name;
    string _symbol; 

    function name() external view returns(string memory){
        return _name;
    }

    function sybmol() external view returns(string memory){
        return _symbol;
    }

    function decimals() external pure returns(uint){
        return 18; // 1 token = 1 wei
    }

    function totalSuply() external view returns(uint){
        return totalTokens;
    }

    modifier enoughTokens(address _from, uint _amount){
        require(balanceOf(_from) >= _amount, "not enough tokens!");
        _;
    }    

    modifier onlyOwner(){
        require(msg.sender == owner, "not an owner!");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint initialSupply, address shop){
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        mint(initialSupply, shop); // чеканка монет, ввод монет в оборот
    }

    function balanceOf(address account) public view returns(uint){
        return balances[account];
    }
    
    function transfer(address to, uint amount) external enoughTokens(msg.sender, amount){ 
        _beforeTokenTransfer(msg.sender, to, amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function mint(uint amount, address shop) public onlyOwner{
        _beforeTokenTransfer(address(0), shop, amount);

        balances[shop] += amount;
        totalTokens += amount;
        emit Transfer(address(0), shop, amount);
    }

    function burn(address _from, uint amount) public onlyOwner {
        _beforeTokenTransfer(_from, address(0), amount);
        balances[_from] -= amount;
        totalTokens -= amount;
    }

    function allowance(address _owner, address spender) public view returns(uint){
        return allowances[_owner][spender];
    }

    function approve(address spender, uint amount) public{
        _approve(msg.sender, spender, amount);
    }

    function _approve(address sender, address spender, uint amount) internal virtual{
        allowances[sender][spender] = amount;
        emit Approve(sender, spender, amount);
    }

    function tranferFrom(address sender, address recipient, uint amount) public enoughTokens(sender, amount){
        _beforeTokenTransfer(sender, recipient, amount);
        // require(allowances[sender][recipient] >= amount, "check allowance!");
        // allowances[sender][recipient] -= amount; неверно
        allowances[sender][msg.sender] -= amount;

        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual {} // не часть стандарта
}

contract MerandToken is ERC20{
    constructor(address shop) ERC20("MerandToken", "MRT", 100, shop) { }
}

contract MerandShop {
    IERC20 public token; // специальный объект, который обращается к нашему интерфейсу
    address payable public owner; 
    event Bought(uint _amount, address indexed _buyer);
    event Sold(uint _amount, address indexed _seller);

    constructor(){
        token = new MerandToken(address(this));
        owner = payable(msg.sender);
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "not an owner!");
        _;
    }

    function sell(uint _amountToSell) external {
        require(
            _amountToSell > 0 && 
            token.balanceOf(msg.sender) >= _amountToSell, 
            "incorrect amount!"
        );

        uint allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amountToSell, "check allowance");

        token.tranferFrom(msg.sender, address(this), _amountToSell);

        payable(msg.sender).transfer(_amountToSell); 
        // 2300 газа на то чтобы перевести денежные средства, если произошла ошибка, то тогда вся транзакция будет откачена и будет порождена ошибка
        // call (низкоуровневый вызов) позволяет указать сколько мы денег отправляем, и можем указать лимит по газу, используется в более сложных случаях
        // send 2300 по газу, если произошла ошибка, то тогда транзакция не будет откачена и не будет порождена ошибка, а просто вернётся false

        emit Sold(_amountToSell, msg.sender);
    }

    // recieve должен быть всегда external и payable
    receive() external payable {
        uint tokensToBuy = msg.value; // 1 wei = 1 token
        require(tokensToBuy > 0, "not enough funds!");

        require(tokenBalance() >= tokensToBuy, "not enough tokens!");

        token.transfer(msg.sender, tokensToBuy);
        emit Bought(tokensToBuy, msg.sender);
    } 

    function tokenBalance() public view returns(uint){
        return token.balanceOf(address(this));
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    // не часть стандарта
    function name() external view returns(string memory); // название токена

    function sybmol() external view returns(string memory); // краткое название токена

    function decimals() external pure returns(uint); // сколько знаков после запятой

    // ниже функции стандарта ERC20

    function totalSuply() external view returns(uint); // кол-во токенов

    function balanceOf(address account) external view returns(uint); // для проверки баланса 

    function transfer(address to, uint amount) external; // для пересылки токенов

    function allowance(address _owner, address spender) external view returns(uint); // функция для того чтобы можно было с третьего аккаунта списать токены с первого аккаунта (тк делаем магазин) 

    function approve(address spender, uint amount) external; // кто может списывать токены и в каком количестве 

    function tranferFrom(address sender, address recipient, uint amount) external; // от куда и куда и сколько 

    event Transfer(address indexed from, address indexed to, uint amount); // если поле индексировано,то мы сможем потом по нему сделать поиск

    event Approve(address indexed owner, address indexed to, uint amount);
}
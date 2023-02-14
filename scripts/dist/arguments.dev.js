"use strict";

/*
Arguments to create a new event by posting a new contract with
the parameters on chain 

Onece keyed in as a trial, 
npx hardhat verify --constructor-args scripts/arguments.js  0x9c1311eefaBF95c48B20F3BaC2Bbb9e1224D5621
where that is the deployed contract address 
*/
module.exports = [["a", "b"], [1, 1], [1, 1], "nice", "02021200", "capitol", 1, 1, "yo"];
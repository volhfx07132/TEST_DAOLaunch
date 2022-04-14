const Presale01 = artifacts.require("Presale01");
var chaiAsPromised = require("chai-as-promised");
var chai = require("chai");
const { assert } = require("chai");
chai.use(chaiAsPromised);
var expect = chai.expect;
var daoLaunchInstance;
contract("Presale01", accounts => {
    describe("Start initialize smart contract", function(){
        it("Daolaunch deployment", async() => {
            daoLaunchInstance = await Presale01.deployed();
            assert(daoLaunchInstance != undefined, "Smart contract should be defined");
        })
        it("Check account of UNI_FACTORY for initializing", function(){
            return daoLaunchInstance.UNI_FACTORY().then(function(result){
                assert(result == "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73");
            })
        })
        it("Check account of WETH for initializing", function(){
            return daoLaunchInstance.WETH().then(function(result){
                assert(result == "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c");
            })
        })
        it("Check account of PRESALE_SETTINGS for initializing", function(){
            return daoLaunchInstance.PRESALE_SETTINGS().then(function(result){
                assert(result == "0xcFb2Cb97028c4e2fe6b868D685C00ab96e6Ec370");
            })
        })
        it("Check account of PRESALE_SETTINGS for initializing", function(){
            return daoLaunchInstance.PRESALE_SETTINGS().then(function(result){
                assert(result == "0xcFb2Cb97028c4e2fe6b868D685C00ab96e6Ec370");
            })
        })
        it("Check account of DAOLAUNCH_DEV for initializing", function(){
            return daoLaunchInstance.DAOLAUNCH_DEV().then(function(result){
                assert(result == "0x75d69272c5A9d6FCeC0D68c547776C7195f73feA");
            })
        })
        it("Check account of PRESALE_GENERATOR for initializing", function(){
            return daoLaunchInstance.PRESALE_GENERATOR().then(function(result){
                assert(result == "0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "Result: "+result);
            })
        })
    });

    describe("Initialize the parameter of struct", function() {
        it("Initialize struct PresaleInfo", function() {
            return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 358208, 1, 358208, 1, 50, 1, 1649820304, 1659820304, 2592000], {from: accounts[0]}).then(function(result){
             expect(result).to.not.be.an("Error");
            })
        })

        it("Initialize struct PresalPresaleFeeInfoeInfo", function() {
            return daoLaunchInstance.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", [20, 20, 1659920304], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]}).then(function(result){
            expect(result).to.not.be.an("Error");
            })
        })

        it("Initialize struct VestingPeriod", function() {
            return daoLaunchInstance.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1659930304, 30, 600, 35, 600000] , 0, 100, {from: accounts[0]}).then(function(result){
            expect(result).to.not.be.an("Error");
            })
        })
    })

    describe("Should check user deposit token", async() => {
        it("Check user choce status WHILELIST => ACTIVE ",  async() => {
            let daoLaunchInstanceCheck = await Presale01.deployed();
            assert(daoLaunchInstanceCheck != undefined, "Smart contract should be defined");                                        
            return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 200, 1, 200, 1, 50, 1, 1649836299, 1649936299, 2592000], {from: accounts[0]}).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x8310cE9cA24da3e7848F6eac4Ef7D08A3225E768", [20, 20, 1649956299], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init3(true, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1649957299, 30, 600, 35, 600] , 0, 100, {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.presaleStatus()
            }).then(function(result) {
                assert.equal(result, 1, "Status of presale must be 1 === ACTIVE");
                return daoLaunchInstanceCheck.userDeposit(4, 28, "0x3e5cd55051066625a58eb3f6b3597349049e7520604c3b537a1a9d69a37030c0", "0x4c1ea7e724bef1bfc73f78a3bbbe7ee58255b6132cdba0efe09f7884f3ab6743", {from: accounts[0]})
            }).then(function(result) {
                expect(result).to.not.be.an("Error");
                return daoLaunchInstance.TOTAL_FEE()
            }).then(function(result){
                assert(result == 0, "Smart contract should be defined: "+result);
            })
        })
        
        it("Check user choce status ANYONE => ACTIVE ",  async() => {
            let daoLaunchInstanceCheck = await Presale01.deployed();
            assert(daoLaunchInstanceCheck != undefined, "Smart contract should be defined");                                    
            return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 200, 1, 200, 1, 50, 1, 1649842973, 1659842973, 2592000], {from: accounts[0]}).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x8310cE9cA24da3e7848F6eac4Ef7D08A3225E768", [20, 20, 1649956299], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1649957299, 30, 600, 35, 600] , 0, 100, {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.presaleStatus()
            }).then(function(result) {
                assert.equal(result, 1, "Status of presale must be 1 === ACTIVE");
                return daoLaunchInstanceCheck.userDeposit(3, 28, "0x3e5cd55051066625a58eb3f6b3597349049e7520604c3b537a1a9d69a37030c0", "0x4c1ea7e724bef1bfc73f78a3bbbe7ee58255b6132cdba0efe09f7884f3ab6743", {from: accounts[0]})
            }).then(function(result) {
                expect(result).to.not.be.an("Error");
                return daoLaunchInstance.TOTAL_FEE();
            }).then(function(result){
                assert(result != 0, "Smart contract should be defined: "+result);
            })
        })
    })

    describe("Should Check user withdraw Base Tokens", async() => {
        it("Check user withdraw Base Tokens",  async() => {
            var daoLaunchInstanceCheck = await Presale01.deployed();
            assert(daoLaunchInstanceCheck != undefined, "Smart contract should be defined");                                        
            return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[100000000, 1000, 200, 1, 200, 20, 50, 1, 1649816299, 1649826299, 2592000], {from: accounts[0]}).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x8310cE9cA24da3e7848F6eac4Ef7D08A3225E768", [20, 20, 1649956299], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1649957299, 30, 600, 35, 600] , 0, 100, {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.presaleStatus()
            }).then(function(result) {
                assert.equal(result, 3, "Status of presale must be 3 === FAILED"+result);
                return daoLaunchInstance.userWithdrawBaseTokens()
            }).then(function(result) {
                expect(result).to.not.be.an("Error");
            })
        })
    })

    describe("Should check owner refund tokens", async() => {
        it("Check user withdraw Base Tokens",  async() => {
            var daoLaunchInstanceCheck = await Presale01.deployed();
            assert(daoLaunchInstanceCheck != undefined, "Smart contract should be defined");                                        
            return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 200, 1, 200, 20, 50, 1, 1649816299, 1649826299, 2592000], {from: accounts[0]}).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x8310cE9cA24da3e7848F6eac4Ef7D08A3225E768", [20, 20, 1649956299], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1649957299, 30, 600, 35, 600] , 0, 100, {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.presaleStatus()
            }).then(function(result) {
                assert.equal(result, 3, "Status of presale must be 3 === FAILED"+result);
                return daoLaunchInstance.ownerRefundTokens({from: "0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8"})
            }).then(function(result) {
                expect(result).to.not.be.an("Error");
            })
        })
    })

    describe("Should check status of presale", async() => {
        it("Check status of Presale FAILED",  async() => {
            var daoLaunchInstanceCheck = await Presale01.deployed();
            assert(daoLaunchInstanceCheck != undefined, "Smart contract should be defined");                                        
            return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 200, 1, 200, 20, 50, 1, 1649816299, 1649826299, 2592000], {from: accounts[0]}).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x8310cE9cA24da3e7848F6eac4Ef7D08A3225E768", [20, 20, 1649956299], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1649957299, 30, 600, 35, 600] , 0, 100, {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.presaleStatus()
            }).then(function(result) {
                assert.equal(result, 3, "Status of presale must be 3 === FAILED"+result);
            })
        })

        it("Check status of Presale not ACTIVE", async() => {
            var daoLaunchInstanceCheck = await Presale01.deployed();
            assert(daoLaunchInstanceCheck != undefined, "Smart contract should be defined");
            return daoLaunchInstanceCheck.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 358208, 1, 358208, 1, 50, 1, 1749820304, 1759820304, 2592000], {from: accounts[0]}).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", [20, 20, 1759920304], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1759930304, 30, 600, 35, 600000] , 0, 100, {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.presaleStatus().then(function(result){
                    assert.equal(result, 0, "Status of presale must be 0 === NOT ACTIVE");
                })
            })
        })

        it("Check status of Presale SUCCESS",  async() => {
            var daoLaunchInstanceCheck = await Presale01.deployed();
            assert(daoLaunchInstanceCheck != undefined, "Smart contract should be defined");
            return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 200, 1, 200, 1, 50, 1, 1649836299, 1649936299, 2592000], {from: accounts[0]}).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x8310cE9cA24da3e7848F6eac4Ef7D08A3225E768", [20, 20, 1649956299], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1649957299, 30, 600, 35, 600] , 0, 100, {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.presaleStatus()
            }).then(function(result) {
                assert.equal(result, 1, "Status of presale must be 1 === ACTIVE");
                return daoLaunchInstanceCheck.userDeposit(250, 28, "0x3e5cd55051066625a58eb3f6b3597349049e7520604c3b537a1a9d69a37030c0", "0x4c1ea7e724bef1bfc73f78a3bbbe7ee58255b6132cdba0efe09f7884f3ab6743", {from: accounts[0]})
            }).then(function(result) {
                expect(result).to.not.be.an("Error");
                return daoLaunchInstanceCheck.presaleStatus()
            }).then(function(result) {
                assert.equal(result, 2, "Status of presale must be 1 === ACTIVE"+result);
            })
        })

        it("Check status of Presale ACTIVE", function() {
            return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 358208, 1, 358208, 1, 50, 1, 1649820304, 1659820304, 2592000], {from: accounts[0]}).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstance.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", [20, 20, 1759920304], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstance.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1759930304, 30, 600, 35, 600000] , 0, 100, {from: accounts[0]})
            }).then(function(result){
                expect(result).to.not.be.an("Error");
                return daoLaunchInstance.presaleStatus().then(function(result){
                    assert.equal(result, 1, "Status of presale must be  === ACTIVE");
                })
            })
        }) 
    })

    describe("Should check user token deposit", async() => {
        it("Check user with draw tokens", function() {
            it("Check status of Presale SUCCESS",  async() => { 
                var daoLaunchInstanceCheck = await Presale01.deployed();
                assert(daoLaunchInstanceCheck != undefined, "Smart contract should be defined");
                return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 200, 1, 200, 1, 50, 1, 1649836299, 1649936299, 2592000], {from: accounts[0]}).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x8310cE9cA24da3e7848F6eac4Ef7D08A3225E768", [20, 20, 1649956299], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
                }).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1649957299, 30, 600, 35, 600] , 0, 100, {from: accounts[0]})
                }).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.presaleStatus()
                }).then(function(result) {
                    assert.equal(result, 1, "Status of presale must be 1 === ACTIVE");
                    return daoLaunchInstanceCheck.userDeposit(250, 28, "0x3e5cd55051066625a58eb3f6b3597349049e7520604c3b537a1a9d69a37030c0", "0x4c1ea7e724bef1bfc73f78a3bbbe7ee58255b6132cdba0efe09f7884f3ab6743", {from: accounts[0]})
                }).then(function(result) {
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.presaleStatus()
                }).then(function(result) {
                    assert.equal(result, 2, "Status of presale must be 1 === ACTIVE"+result);
                    return daoLaunchInstanceCheck.userWithdrawTokens();
                }).then(function(result) {
                    expect(result).to.not.be.an("Error");
                })
            })
        })
    })

    describe("Should check caller list on uniswap", async() => {
        it("Check user caller list on uniswap", function() {
            it("Check status of Presale SUCCESS",  async() => { 
                var daoLaunchInstanceCheck = await Presale01.deployed();
                assert(daoLaunchInstanceCheck != undefined, "Smart contract should be defined");
                return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 200, 1, 200, 1, 50, 1, 1649836299, 1649936299, 2592000], {from: accounts[0]}).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x8310cE9cA24da3e7848F6eac4Ef7D08A3225E768", [20, 20, 1649956299], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
                }).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1649957299, 30, 600, 35, 600] , 0, 100, {from: accounts[0]})
                }).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.presaleStatus()
                }).then(function(result) {
                    assert.equal(result, 1, "Status of presale must be 1 === ACTIVE");
                    return daoLaunchInstanceCheck.userDeposit(250, 28, "0x3e5cd55051066625a58eb3f6b3597349049e7520604c3b537a1a9d69a37030c0", "0x4c1ea7e724bef1bfc73f78a3bbbe7ee58255b6132cdba0efe09f7884f3ab6743", {from: accounts[0]})
                }).then(function(result) {
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.presaleStatus()
                }).then(function(result) {
                    assert.equal(result, 2, "Status of presale must be 1 === ACTIVE"+result);
                    return daoLaunchInstanceCheck.listOnUniswap({from: "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610"});
                }).then(function(result) {
                    expect(result).to.not.be.an("Error");
                })
            })
        })
    })

    describe("Should owner with drawtoken", async() => {
        it("Check user caller list on uniswap", function() {
            it("Check status of Presale SUCCESS",  async() => { 
                var daoLaunchInstanceCheck = await Presale01.deployed();
                assert(daoLaunchInstanceCheck != undefined, "Smart contract should be defined");
                return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 200, 1, 200, 1, 50, 1, 1649836299, 1649936299, 2592000], {from: accounts[0]}).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x8310cE9cA24da3e7848F6eac4Ef7D08A3225E768", [20, 20, 1649956299], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
                }).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1649957299, 30, 600, 35, 600] , 0, 100, {from: accounts[0]})
                }).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.presaleStatus()
                }).then(function(result) {
                    assert.equal(result, 1, "Status of presale must be 1 === ACTIVE");
                    return daoLaunchInstanceCheck.userDeposit(250, 28, "0x3e5cd55051066625a58eb3f6b3597349049e7520604c3b537a1a9d69a37030c0", "0x4c1ea7e724bef1bfc73f78a3bbbe7ee58255b6132cdba0efe09f7884f3ab6743", {from: accounts[0]})
                }).then(function(result) {
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.presaleStatus()
                }).then(function(result) {
                    assert.equal(result, 2, "Status of presale must be 1 === ACTIVE"+result);
                    return daoLaunchInstanceCheck.ownerWithdrawTokens({from: "0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8"});
                }).then(function(result) {
                    expect(result).to.not.be.an("Error");
                })
            })
        })
    })

    describe("Should user caller list on uniswap", async() => {
        it("Check user caller list on uniswap", function() {
            it("Check status of Presale SUCCESS",  async() => { 
                var daoLaunchInstanceCheck = await Presale01.deployed();
                assert(daoLaunchInstanceCheck != undefined, "Smart contract should be defined");
                return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 200, 1, 200, 1, 50, 1, 1649836299, 1649936299, 2592000], {from: accounts[0]}).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x8310cE9cA24da3e7848F6eac4Ef7D08A3225E768", [20, 20, 1649956299], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
                }).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1649957299, 30, 600, 35, 600] , 0, 100, {from: accounts[0]})
                }).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.presaleStatus()
                }).then(function(result) {
                    assert.equal(result, 1, "Status of presale must be 1 === ACTIVE");
                    return daoLaunchInstanceCheck.userDeposit(100, 28, "0x3e5cd55051066625a58eb3f6b3597349049e7520604c3b537a1a9d69a37030c0", "0x4c1ea7e724bef1bfc73f78a3bbbe7ee58255b6132cdba0efe09f7884f3ab6743", {from: accounts[0]})
                }).then(function(result) {
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.presaleStatus()
                }).then(function(result) {
                    assert.equal(result, 2, "Status of presale must be 1 === ACTIVE"+result);
                    return daoLaunchInstanceCheck.userRefundTokens({from: "0x96FC13de758952c7D77b0F1a11634831185a16Da"});
                }).then(function(result) {
                    expect(result).to.not.be.an("Error");
                })
            })
        })
    })

    describe("Should finalize presale", async() => {
        it("Check user finalize presale", function() {
            it("Check status of Presale SUCCESS",  async() => { 
                var daoLaunchInstanceCheck = await Presale01.deployed();
                assert(daoLaunchInstanceCheck != undefined, "Smart contract should be defined");
                return daoLaunchInstance.init1("0xE6F5a58C67cF4C2eC7F71AFCD7b23c600afF80f8",[500000000, 1000, 200, 1, 200, 1, 50, 1, 1649836299, 1649936299, 2592000], {from: accounts[0]}).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.init2("0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x8310cE9cA24da3e7848F6eac4Ef7D08A3225E768", [20, 20, 1649956299], "0x2453E2cD5069f858A0dde0aF38E46E11f6351c45", "0x514B40b46bcfb673C5ffBcFe11fd74d6E22840Be", {from: accounts[0]})
                }).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.init3(false, "0xf35a5ae8acd7fe1f52e6785f42f328ef27a61610" , [1649957299, 30, 600, 35, 600] , 0, 100, {from: accounts[0]})
                }).then(function(result){
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.presaleStatus()
                }).then(function(result) {
                    assert.equal(result, 1, "Status of presale must be 1 === ACTIVE");
                    return daoLaunchInstanceCheck.userDeposit(100, 28, "0x3e5cd55051066625a58eb3f6b3597349049e7520604c3b537a1a9d69a37030c0", "0x4c1ea7e724bef1bfc73f78a3bbbe7ee58255b6132cdba0efe09f7884f3ab6743", {from: accounts[0]})
                }).then(function(result) {
                    expect(result).to.not.be.an("Error");
                    return daoLaunchInstanceCheck.finalize({from: "0x96FC13de758952c7D77b0F1a11634831185a16Da"});
                }).then(function(result) {
                    expect(result).to.not.be.an("Error");
                })
            })
        })
    })
})
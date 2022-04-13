const Presale01 = artifacts.require("Presale01");

module.exports = function (deployer) {
  deployer.deploy(Presale01, "0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", ["0x5bD4ECAa08dFA56423c0E83546e979e386003ccC", "0x6227F7B236e65a16cADfd71A6B6d4949400d71AD", "0xe9e73E046c753a67F615B0c6e925C60374fD06a8"]);
};

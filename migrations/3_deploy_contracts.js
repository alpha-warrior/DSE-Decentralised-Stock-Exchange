const Nifty = artifacts.require("Nifty");
    
    module.exports = function (deployer) {
      deployer.deploy(Nifty,"Nifty",1000,10000);
    };
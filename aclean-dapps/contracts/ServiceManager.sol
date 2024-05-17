// SPDX-License-Identifier: PRIVATE
import "./ServiceAgreement.sol";

pragma solidity ^0.8.4;

contract ServiceManager {
    mapping(address => ServiceProvider) public serviceProviders;
    address[] private serviceProviderIndexes;

    mapping(address => address[]) private clientAgreements;
    mapping(address => address[]) private providerAgreements;
    enum ServiceCategory {
        CuciAC,
        TambahFreon,
        ServiceAC,
        PasangAC,
        Tidur
    }

    modifier validProvidersOnly(address _provider) {
        require(serviceProviderIndexes.length != 0, "No Service Providers");
        require(serviceProviderIndexes[serviceProviders[_provider].index] == _provider, "Service Provider does not exist");
        _;
    } 

    struct ServiceProvider {
        address owner;
        string companyName;
        string email;
        string phone;
        uint256 serviceAmount;
        ServiceCategory serviceCategory;
        uint256 index;
    }

    event RegisteredServiceProvider(address indexed owner);
    event NewAgreement(
        address indexed client, 
        address indexed provider, 
        address agreementAddress
    );
    event ErrorNotice(string message);
    event ErrorNoticeBytes(bytes data);

    function createNewServiceProvider(
        string memory _companyName,
        string memory _email,
        string memory _phone,
        uint256 _serviceAmount,
        ServiceCategory _serviceCategory
    ) external {
        serviceProviderIndexes.push(msg.sender);
        serviceProviders[msg.sender] = ServiceProvider({
            owner: msg.sender,
            companyName: _companyName,
            email: _email,
            phone: _phone,
            serviceAmount: _serviceAmount,
            serviceCategory:  _serviceCategory,
            index: serviceProviderIndexes.length - 1
        });

        emit RegisteredServiceProvider(msg.sender);
    }

    function getServiceProviders(address _address) 
        external
        view 
        validProvidersOnly(_address)
        returns(ServiceProvider memory) 
    {
        return serviceProviders[_address];
    }
    
    function getServiceProviders() external view returns (ServiceProvider[] memory) {
        ServiceProvider[] memory validServiceProviders = new ServiceProvider[](serviceProviderIndexes.length);
    
        for(uint i = 0; i < serviceProviderIndexes.length; i++) {
            address currentAddress = serviceProviderIndexes[i];

            if (i == serviceProviders[currentAddress].index) {
                validServiceProviders[i] = serviceProviders[currentAddress];
            }
        }

        return validServiceProviders;
    }
    
    function createServiceAgreement(address _provider) external validProvidersOnly(_provider) {
        require(_provider != msg.sender, "Provider cannot create service agreement with themselves");
        uint256 amount = serviceProviders[_provider].serviceAmount;
        require(msg.sender.balance >= amount, "Insufficient funds");
        try new ServiceAgreement(msg.sender, _provider, amount) returns (ServiceAgreement serviceAgreement) {
            address agreementAddress = address(serviceAgreement);

            address[] storage ca = clientAgreements[msg.sender];
            ca.push(agreementAddress);

            address[] storage pa = providerAgreements[_provider];
            pa.push(agreementAddress);  

            emit NewAgreement(msg.sender, _provider, agreementAddress);
        } catch Error(string memory reason) {
            emit ErrorNotice(reason);
        } catch (bytes memory reason) {
            emit ErrorNoticeBytes(reason);
        }
    }

    function getClientServiceAgreements(address _clientAddress) external view returns(address[] memory) {
        return clientAgreements[_clientAddress];
    }

    function getProviderServiceAgreements(address _providerAddress) external view returns(address[] memory) {
        return providerAgreements[_providerAddress];
    }
}

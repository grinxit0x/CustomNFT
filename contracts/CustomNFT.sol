// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CustomNFT is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable,
    ERC721Burnable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    // Estructura para almacenar información de cada NFT
    struct NFT {
        uint256 idNft;
        string baseURL;
    }

    // Variable para representar el número máximo de NFTs que un usuario puede crear
    uint256 public maxNFTsPerUser = 10;

    uint256 public approvedUserFee = 0.1 ether;

    // Mapeo para almacenar las colecciones de NFTs por usuario
    mapping(address => NFT[]) private nftsByCollection;

    // Lista de usuarios aprobados
    mapping(address => bool) private approvedUsers;

    // Modificador para restringir el acceso a usuarios aprobados
    modifier onlyApprovedUsers() {
        require(approvedUsers[msg.sender], "Not approved user");
        _;
    }

    // Función para agregar usuarios aprobados
    function addApprovedUser(address user) public payable {
        // Verificar que el remitente haya pagado la tarifa requerida
        require(msg.value == approvedUserFee, "Fee required");

        // Agregar el usuario a la lista de aprobados
        approvedUsers[user] = true;

        payable(owner()).transfer(msg.value);
    }

    // Función para eliminar usuarios aprobados
    function removeApprovedUser(address user) public onlyOwner {
        // Eliminar el usuario de la lista de aprobados
        approvedUsers[user] = false;
    }

    // Función para crear un nuevo NFT en la colección del usuario
    function createNFT(string memory baseURL) public onlyApprovedUsers {
        require(
            nftsByCollection[msg.sender].length < maxNFTsPerUser,
            "Maximum number of NFTs reached"
        );
        uint256 currentTokenId = _tokenIdCounter.current();
        // Crear el nuevo NFT y agregarlo a la colección del usuario
        NFT memory newNFT = NFT({idNft: currentTokenId, baseURL: baseURL});
        nftsByCollection[msg.sender].push(newNFT);

        _tokenIdCounter.increment();

        // Emitir evento de creación de NFT
        emit Transfer(address(0), msg.sender, currentTokenId);
    }

    // Función para obtener información de un NFT en particular en la colección del usuario
    function getNFT(
        address user,
        uint256 index
    ) public view returns (uint256, string memory) {
        NFT memory nft = nftsByCollection[user][index];
        return (nft.idNft, nft.baseURL);
    }

    // Función para obtener la cantidad de NFTs en la colección del usuario
    function getNFTCount(address user) public view returns (uint256) {
        return nftsByCollection[user].length;
    }

    // Función para transferir un NFT a otro usuario
    function transferNFT(address to, uint256 tokenId) public {
        // Verificar que el remitente sea el propietario del NFT
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");

        // Transferir el NFT al nuevo propietario
        _transfer(msg.sender, to, tokenId);
    }

    // Función para quemar un NFT de la colección del usuario
    function burnNFT(uint256 tokenId) public {
        // Verificar que el remitente sea el propietario del NFT
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");

        // Eliminar el NFT de la colección del usuario
        uint256 index = _indexOf(tokenId);
        delete nftsByCollection[msg.sender][index];

        // Quemar el NFT
        _burn(tokenId);
    }

    // Función para cambiar el límite máximo de NFTs por usuario
    function setMaxNFTsPerUser(uint256 newMax) public onlyOwner {
        maxNFTsPerUser = newMax;
    }

    //función para cambiar el precio del approved user
    function setApprovedUserFee(uint256 newFee) public onlyOwner {
        approvedUserFee = newFee;
    }

    // Función para obtener el índice de un NFT en la colección del usuario
    function _indexOf(uint256 tokenId) private view returns (uint256) {
        NFT[] storage nfts = nftsByCollection[msg.sender];
        for (uint256 i = 0; i < nfts.length; i++) {
            if (nfts[i].idNft == tokenId) {
                return i;
            }
        }
        revert("NFT not found");
    }

    // Constructor del contrato
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        // Agregar al owner a la lista de aprobados
        approvedUsers[msg.sender] = true;
    }

    // Funciones de OpenZeppelin que se deben implementar para cumplir con el estándar ERC721
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        // Concatenamos la URL base de IPFS con el token ID y la extensión del archivo JSON
        string
            memory baseURI = "ipfs://QmPcZm5W8to4PzsjX9KLaf4c4jQ2iqi29aLZb1tZvSgSx/";
        bytes32 tokenIdBytes = bytes32(tokenId);
        string memory tokenIdString = bytes32ToString(tokenIdBytes);
        string memory json = string(abi.encodePacked(tokenIdString, ".json"));
        return string(abi.encodePacked(baseURI, json));
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._transfer(from, to, tokenId);
    }

    //helpers

    function bytes32ToString(
        bytes32 _bytes32
    ) internal pure returns (string memory) {
        uint8 _i = 0;
        bytes memory _bytesArray = new bytes(64);
        for (uint256 _j = 0; _j < 32; _j++) {
            bytes1 _byte = bytes1(uint8(uint256(_bytes32) * 2 ** (8 * _j)));
            if (_byte != 0) {
                _bytesArray[_i++] = _byte;
            }
        }
        bytes memory _bytesArrayTrimmed = new bytes(_i);
        for (uint256 _j = 0; _j < _i; _j++) {
            _bytesArrayTrimmed[_j] = _bytesArray[_j];
        }
        return string(_bytesArrayTrimmed);
    }
}

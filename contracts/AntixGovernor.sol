// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.29;

// import {BurnMintERC677} from "@chainlink/contracts/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";
// import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
// import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
// import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
// import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
// import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
// import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
// import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
// import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
// import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";

// contract AntixGovernor is
//     Governor,
//     GovernorSettings,
//     GovernorCountingSimple,
//     GovernorVotes,
//     GovernorVotesQuorumFraction
// {
//     constructor(
//         ERC20Votes token
//     )
//         Governor("AntixGovernor")
//         GovernorSettings(
//             1, // 1 block voting delay
//             45818, // 1 week voting period (assuming 13.2s block time)
//             0 // proposal threshold
//         )
//         GovernorVotes(token)
//         GovernorVotesQuorumFraction(4) // 4% quorum
//     {}

//     // Функции, требующие переопределения
//     function votingDelay()
//         public
//         view
//         override(GovernorSettings)
//         returns (uint256)
//     {
//         return super.votingDelay();
//     }

//     function votingPeriod()
//         public
//         view
//         override(GovernorSettings)
//         returns (uint256)
//     {
//         return super.votingPeriod();
//     }

//     function quorum(
//         uint256 blockNumber
//     )
//         public
//         view
//         override(Governor, GovernorVotesQuorumFraction)
//         returns (uint256)
//     {
//         return super.quorum(blockNumber);
//     }

//     function proposalThreshold()
//         public
//         view
//         override(Governor, GovernorSettings)
//         returns (uint256)
//     {
//         return super.proposalThreshold();
//     }

//     // Необходимые переопределения функций Governor
//     function propose(
//         address[] memory targets,
//         uint256[] memory values,
//         bytes[] memory calldatas,
//         string memory description
//     ) public override(Governor) returns (uint256) {
//         return super.propose(targets, values, calldatas, description);
//     }

//     function cancel(
//         address[] memory targets,
//         uint256[] memory values,
//         bytes[] memory calldatas,
//         bytes32 descriptionHash
//     ) public override(Governor) returns (uint256) {
//         return super.cancel(targets, values, calldatas, descriptionHash);
//     }

//     function _execute(
//         uint256 proposalId,
//         address[] memory targets,
//         uint256[] memory values,
//         bytes[] memory calldatas,
//         bytes32 descriptionHash
//     ) internal override(Governor) {
//         super._execute(proposalId, targets, values, calldatas, descriptionHash);
//     }

//     function _cancel(
//         address[] memory targets,
//         uint256[] memory values,
//         bytes[] memory calldatas,
//         bytes32 descriptionHash
//     ) internal override(Governor) returns (uint256) {
//         return super._cancel(targets, values, calldatas, descriptionHash);
//     }

//     function _executor() internal view override(Governor) returns (address) {
//         return super._executor();
//     }

//     function supportsInterface(
//         bytes4 interfaceId
//     ) public view override(Governor) returns (bool) {
//         return super.supportsInterface(interfaceId);
//     }
// }

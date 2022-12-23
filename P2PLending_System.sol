// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
contract BasicLoan {
    struct Terms {
        uint256 loanDaiAmount;
        uint256 feeDaiAmount;
        uint256 ethCollateralAmount;
        uint256 repayByTimestamp;    
    }
    Terms public terms;
    enum LoanState {Created, Funded,Taken}
    LoanState public state;
    SafeERC20 public DAI;
    modifier onlyInState(LoanState expectedState) {
        require(state == expectedState, "Not allowed in this state");
    }

        address payable lender;
        address payable borrower;
        address daiAddress;

        constructor(Terms memory _terms, address _daiAddress) public {

        DAI = SafeERC20(daiAddress);
        terms = _terms;
        daiAddress = _daiAddress;
        lender = msg.sender;
        state = LoanState.Created;
        }

        function fundLoan() public onlyInState(LoanState.Created) {
            state = LoanState.Funded;
            DAI(daiAddress).transferFrom(
                msg.sender,
                address(this),
                terms.loanDaiAmount
            );
        }
        function takeALoanAndAcceptLoanTerms()
        public
        payable
        onlyInState(LoanState.Funded)
        {
            require(
                msg.value == terms.ethCollateralAmount,
                "Invalid collateral amount"
            );

            borrower = msg.sender;
            state = LoanState.Taken;
            DAI(daiAddress).transfer(borrower, terms.loanDaiAmount);
        }
        function repay() public onlyInState(LoanState.Taken){

            require(msg.sender == borrower, "Only the borrower can repay the loan");
            DAI(daiAddress).transferFrom(
                borrower,
                lender,
                terms.loanDaiAmount + terms.feeDaiAmount
            );

            DAI.transferFrom(lender, address(this), terms.loanDaiAmount);
            
            selfdestruct(borrower);
        }
        function liquidate() public onlyInState(LoanState.Taken) {
            require(msg.sender == lender, "Only the lender can liquidate the loan");
            require(
                block.timestamp >= terms.repayByTimestamp,
                "Can not liquidate before the loan is due"
            );
            selfdestruct(lender);
        }    
    }
import Config "../config";
import Ledger "Ledger";
import ICRC1Account "ICRC1Account";
import ICRC1 "ICRC1";
import Account "Account";

import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import P "mo:base/Prelude";

module {
  // private let icpLedger : Ledger.Self = actor (Config.LEDGER_CANISTER_ID);
  // private let ckbtcLedger : ICRC1.Self = actor ("");

  public func get_address(token : Text, { owner; subaccount } : ICRC1.Account) : async Blob {
    switch (token) {
      case "ICP" {
        return Account.accountIdentifier(owner, subaccount);
      };
      case "CKBTC" {
        return ICRC1Account.toBlob({ owner; subaccount });
      };
      // case "BTC" {};
      case _ {
        P.unreachable();
      };
    };
  };

  public func balance(token : Text, account : ICRC1.Account) : async Nat64 {
    switch (token) {
      case ("ICP") {
        let ledger : ICRC1.Self = actor (Config.LEDGER_CANISTER_ID);
        let amount = await ledger.icrc1_balance_of(account);
        return Nat64.fromNat(amount);
      };
      case ("CKBTC") {
        let ledger : ICRC1.Self = actor (Config.CKBTC_LEDGER_CANISTER_ID);
        let amount = await ledger.icrc1_balance_of(account);
        return Nat64.fromNat(amount);
      };
      case (_) {};
    };
    return 0;
  };

  public func icrc1_transfer(token : Text, from : ?Blob, to : ICRC1.Account, amount : Nat64) : async ICRC1.Result {
    let args : ICRC1.TransferArg = {
      to = to;
      fee = ?Nat64.toNat(token_fee(token));
      memo = null;
      from_subaccount = from;
      created_at_time = null;
      amount = Nat64.toNat(amount);
    };
    switch (token) {
      case ("ICP") {
        let ledger : ICRC1.Self = actor (Config.LEDGER_CANISTER_ID);
        return await ledger.icrc1_transfer(args);
      };
      case ("CKBTC") {
        let ledger : ICRC1.Self = actor (Config.CKBTC_LEDGER_CANISTER_ID);
        return await ledger.icrc1_transfer(args);
      };
      case (_) {};
    };
    return #Err(#GenericError({ message = "unsupport token"; error_code = 1001 }));
  };

  public func transfer(token : Text, from : ?[Nat8], to : Blob, amount : Nat64) : async ICRC1.Result {
    switch (token) {
      case ("ICP") {
        let ledger : Ledger.Self = actor (Config.LEDGER_CANISTER_ID);
        let args : Ledger.TransferArgs = {
          to = to;
          fee = { e8s = token_fee(token) };
          memo = 0;
          amount = { e8s = amount };
          from_subaccount = from;
          created_at_time = null;
        };
        let ret = await ledger.transfer(args);
        switch (ret) {
          case (#Ok(height)) {
            return #Ok(Nat64.toNat(height));
          };
          case (#Err(err)) {
            return #Err(#GenericError({ message = debug_show (err); error_code = 1002 }));
          };
        };
      };
      case ("CKBTC") {
        let ledger : ICRC1.Self = actor (Config.CKBTC_LEDGER_CANISTER_ID);
        let ret = ICRC1Account.fromBlob(to);
        let fbytes = switch (from) {
          case (?fr) { ?Blob.fromArray(fr) };
          case (_) { null };
        };
        switch (ret) {
          case (#ok(account)) {
            let args : ICRC1.TransferArg = {
              to = account;
              fee = ?Nat64.toNat(token_fee(token));
              memo = null;
              from_subaccount = fbytes;
              created_at_time = null;
              amount = Nat64.toNat(amount);
            };
            return await ledger.icrc1_transfer(args);
          };
          case (#err(err)) {
            return #Err(#GenericError({ message = debug_show (err); error_code = 1002 }));
          };
        };
      };
      case (_) {};
    };

    return #Err(#GenericError({ message = "unsupport token"; error_code = 1001 }));
  };

  public func token_fee(token : Text) : Nat64 {
    switch (token) {
      case ("ICP") {
        return 10000;
      };
      case ("CKBTC") {
        return 10;
      };
      case (_) {
        return 0;
      };
    };
  };
};

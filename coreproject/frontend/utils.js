export function getWhitelist(){
  let env = "mainnet"
  let daoCanisterId = ""
  let mbtCanisterId = ""
  let interfaceCanisterId = ""
  if (env=="mainnet"){
    daoCanisterId = "7mmib-yqaaa-aaaap-qa5la-cai"
    mbtCanisterId = "db3eq-6iaaa-aaaah-abz6a-cai"
    interfaceCanisterId = "7fpd5-oyaaa-aaaap-qa5kq-cai"
  } else {
    daoCanisterId = "rkp4c-7iaaa-aaaaa-aaaca-cai"
    mbtCanisterId = "renrk-eyaaa-aaaaa-aaada-cai"
  }
  const whitelist = [daoCanisterId, mbtCanisterId,interfaceCanisterId];
  return whitelist;
}
import { test, expect } from 'vitest';
import { Clarinet, Tx } from "clarinet"; // Assuming Clarinet for Stacks smart contract testing

test('Create project with valid data', async () => {
  const chain = new Clarinet();
  const deployer = chain.accounts.get("deployer")!;

  const title = "My First Project";
  const contentHash = Buffer.from("abcd1234abcd1234abcd1234abcd1234", "hex");
  const licenseType = "Standard";

  let block = chain.mineBlock([
    Tx.contractCall("CreatS", "create-project", [title, contentHash, licenseType], deployer.address)
  ]);

  const result = block.receipts[0].result;
  expect(result).toEqual(`(ok u1)`);
});

test('Fail to create project with invalid title', async () => {
  const chain = new Clarinet();
  const deployer = chain.accounts.get("deployer")!;

  const invalidTitle = "";
  const contentHash = Buffer.from("abcd1234abcd1234abcd1234abcd1234", "hex");
  const licenseType = "Standard";

  let block = chain.mineBlock([
    Tx.contractCall("CreatS", "create-project", [invalidTitle, contentHash, licenseType], deployer.address)
  ]);

  const result = block.receipts[0].result;
  expect(result).toEqual(`(err u106)`);
});

test('Add collaborator with valid data', async () => {
  const chain = new Clarinet();
  const deployer = chain.accounts.get("deployer")!;
  const collaborator = chain.accounts.get("wallet_1")!;

  let block = chain.mineBlock([
    Tx.contractCall("CreatS", "create-project", ["Project Title", Buffer.from("abcd1234abcd1234abcd1234abcd1234", "hex"), "License Type"], deployer.address)
  ]);

  const projectId = 1;
  const sharePercentage = 10;
  const role = "Developer";

  block = chain.mineBlock([
    Tx.contractCall("CreatS", "add-collaborator", [projectId, collaborator.address, sharePercentage, role], deployer.address)
  ]);

  const result = block.receipts[0].result;
  expect(result).toEqual(`(ok true)`);
});

test('Fail to add collaborator with invalid share percentage', async () => {
  const chain = new Clarinet();
  const deployer = chain.accounts.get("deployer")!;
  const collaborator = chain.accounts.get("wallet_1")!;

  let block = chain.mineBlock([
    Tx.contractCall("CreatS", "create-project", ["Project Title", Buffer.from("abcd1234abcd1234abcd1234abcd1234", "hex"), "License Type"], deployer.address)
  ]);

  const projectId = 1;
  const invalidSharePercentage = 150;  // Above MAX_SHARE_PERCENTAGE
  const role = "Developer";

  block = chain.mineBlock([
    Tx.contractCall("CreatS", "add-collaborator", [projectId, collaborator.address, invalidSharePercentage, role], deployer.address)
  ]);

  const result = block.receipts[0].result;
  expect(result).toEqual(`(err u102)`);
});

test('Distribute revenue and verify collaborator earnings', async () => {
  const chain = new Clarinet();
  const deployer = chain.accounts.get("deployer")!;
  const collaborator = chain.accounts.get("wallet_1")!;

  let block = chain.mineBlock([
    Tx.contractCall("CreatS", "create-project", ["Project Title", Buffer.from("abcd1234abcd1234abcd1234abcd1234", "hex"), "License Type"], deployer.address)
  ]);

  const projectId = 1;
  const sharePercentage = 50;
  const role = "Artist";

  block = chain.mineBlock([
    Tx.contractCall("CreatS", "add-collaborator", [projectId, collaborator.address, sharePercentage, role], deployer.address)
  ]);

  const revenueAmount = 100;
  block = chain.mineBlock([
    Tx.contractCall("CreatS", "distribute-revenue", [projectId, revenueAmount], deployer.address)
  ]);

  const earningsResult = chain.callReadOnlyFn("CreatS", "get-pending-earnings", [projectId, collaborator.address], deployer.address);
  expect(earningsResult.result).toEqual(`(ok u50)`);
});

test('Fail to distribute revenue to inactive project', async () => {
  const chain = new Clarinet();
  const deployer = chain.accounts.get("deployer")!;

  let block = chain.mineBlock([
    Tx.contractCall("CreatS", "create-project", ["Project Title", Buffer.from("abcd1234abcd1234abcd1234abcd1234", "hex"), "License Type"], deployer.address)
  ]);

  const projectId = 1;
  block = chain.mineBlock([
    Tx.contractCall("CreatS", "deactivate-project", [projectId], deployer.address)
  ]);

  const revenueAmount = 100;
  block = chain.mineBlock([
    Tx.contractCall("CreatS", "distribute-revenue", [projectId, revenueAmount], deployer.address)
  ]);

  const result = block.receipts[0].result;
  expect(result).toEqual(`(err u112)`);
});

test('Withdraw earnings with valid amount', async () => {
  const chain = new Clarinet();
  const deployer = chain.accounts.get("deployer")!;
  const collaborator = chain.accounts.get("wallet_1")!;

  let block = chain.mineBlock([
    Tx.contractCall("CreatS", "create-project", ["Project Title", Buffer.from("abcd1234abcd1234abcd1234abcd1234", "hex"), "License Type"], deployer.address)
  ]);

  const projectId = 1;
  const sharePercentage = 20;
  const role = "Collaborator";

  block = chain.mineBlock([
    Tx.contractCall("CreatS", "add-collaborator", [projectId, collaborator.address, sharePercentage, role], deployer.address)
  ]);

  const revenueAmount = 50;
  chain.mineBlock([
    Tx.contractCall("CreatS", "distribute-revenue", [projectId, revenueAmount], deployer.address)
  ]);

  block = chain.mineBlock([
    Tx.contractCall("CreatS", "withdraw-earnings", [projectId], collaborator.address)
  ]);

  const result = block.receipts[0].result;
  expect(result).toEqual(`(ok u10)`);  // 20% of 50 revenue
});

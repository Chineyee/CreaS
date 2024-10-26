import { Clarinet, Tx, Chain, Account, types } from "https://deno.land/x/clarinet@v0.31.0/index.ts";
import { assertEquals } from "https://deno.land/std@0.90.0/testing/asserts.ts";

Clarinet.test({
  name: "Ensure project creation works with valid parameters",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const title = "Test Project";
    const licenseType = "MIT";
    const contentHash = types.buff(new Uint8Array(32)); // Simple 32-byte buffer

    // Create project with valid parameters
    let block = chain.mineBlock([
      Tx.contractCall(
        "creats", 
        "createProject", 
        [types.utf8(title), contentHash, types.utf8(licenseType)], 
        deployer.address
      ),
    ]);

    // Check that the transaction succeeded
    const receipt = block.receipts[0];
    receipt.result.expectOk();

    // Verify project details
    const projectDetails = chain.callReadOnlyFn(
      "creats",
      "getProjectDetails",
      [types.uint(1)], 
      deployer.address
    );

    const expectedProjectDetails = {
      owner: types.principal(deployer.address),
      title: types.utf8(title),
      contentHash: contentHash,
      licenseType: types.utf8(licenseType),
      totalRevenue: types.uint(0),
      isActive: types.bool(true),
      totalCollaborators: types.uint(0),
      totalDistributions: types.uint(0),
      createdAt: types.some(types.uint(0)), // Example placeholder, modify if necessary
    };

    assertEquals(projectDetails.result.expectSome(), expectedProjectDetails);
  },
});

Clarinet.test({
  name: "Ensure collaborator can be added successfully",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const collaborator = accounts.get("wallet_1")!;
    const title = "Test Project";
    const contentHash = types.buff(new Uint8Array(32)); // Simple 32-byte buffer
    const licenseType = "MIT";

    // Create project first
    chain.mineBlock([
      Tx.contractCall(
        "creats",
        "createProject",
        [types.utf8(title), contentHash, types.utf8(licenseType)],
        deployer.address
      ),
    ]);

    // Add collaborator
    const block = chain.mineBlock([
      Tx.contractCall(
        "creats",
        "addCollaborator",
        [types.uint(1), types.principal(collaborator.address), types.uint(20), types.utf8("Developer")],
        deployer.address
      ),
    ]);

    // Verify transaction succeeded
    const receipt = block.receipts[0];
    receipt.result.expectOk();

    // Confirm collaborator info
    const collaboratorInfo = chain.callReadOnlyFn(
      "creats",
      "getCollaboratorInfo",
      [types.uint(1), types.principal(collaborator.address)],
      deployer.address
    );

    const expectedCollaboratorInfo = {
      sharePercentage: types.uint(20),
      earnings: types.uint(0),
      role: types.utf8("Developer"),
      isVerified: types.bool(false),
      addedAt: types.some(types.uint(0)), // Modify as per contract response
      lastDistribution: types.some(types.uint(0)), // Modify as per contract response
    };

    assertEquals(collaboratorInfo.result.expectSome(), expectedCollaboratorInfo);
  },
});

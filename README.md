# Guillotine

Guillotine is a fast, accurate tool to optimize header includes in C family and Swift projects based on BDIndexDB and llvm-project.

Once the project was built with `-index-store-path` option given and the database was set up, Guillotine can scan the TikTok project in ~0.3s for a single file on average. Guillotine does not rely on a successful build but requires completed indexing. It is also independent of the source code, instead it depends on the information the compiler generated. 

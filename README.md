# GuillotineKit

GuillotineKit is a fast, accurate tool to optimize header includes in C family projects based on BDIndexDB and llvm-project.

Once the project was built with `-index-store-path` option given and the database was set up, GuillotineKit can scan the TikTok project in ~0.3s for a single file on average. GuillotineKit does not rely on a successful build but requires completed indexing. It is also independent of the source code, instead it depends on the information the compiler generated. 

## How to use GuillotineCLI

Clone this repository, and in the same path also clone BDIndexDB:
```bash
$ git clone git@code.byted.org:liruijie.x/BDIndexDB.git
```

Enter the repository folder and execute build:
```bash
$ cd GuillotineKit && swift build --configuration release
```

Then you can use GuillotineCLI by executing:
```bash
$ .build/release/Guillotine -h
```
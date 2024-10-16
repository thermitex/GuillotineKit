# GuillotineKit

GuillotineKit is a fast, accurate tool to optimize header includes in C family projects based on BDIndexDB and llvm-project.

Once the project was built with `-index-store-path` option given and the database was set up, GuillotineKit can scan the TikTok project in ~0.3s for a single file on average. GuillotineKit does not rely on a successful build but requires completed indexing. It is also independent of the source code, instead it depends on the information the compiler generated. 

## How to use GuillotineCLI

### Build Guillotine

Clone this repository, and in the same path also clone BDIndexDB:
```bash
$ git clone git@<git_path>/BDIndexDB.git
```

Enter the repository folder and execute build:
```bash
$ cd GuillotineKit && swift build --configuration release
```

Then you can use GuillotineCLI by executing:
```bash
$ .build/release/Guillotine
```

### Sample Usage

For checking includes you need to know where the index information is stored. You can search the building log for `-index-store-path`, and the path follows is index store location. You can pass that path to the executable together with the file you would like to scan:
```bash
$ Guillotine /.../Xcode/DerivedData/.../Index/DataStore path/to/file
```

If you need to delete the lines that are marked unused, use `--delete` or `-d`:
```bash
$ Guillotine path/to/index/store path/to/file --delete
```

If you are searching the entire folder, make sure you add `--folder` or `-f` flag to the command:
```bash
$ Guillotine path/to/index/store path/to/folder --folder --delete
```

When scanning a folder, you can set your custom filter rules using `--match` and `--exclude`:
```bash
$ Guillotine path/to/index/store path/to/folder --folder --match ".*\\.m" --exclude "pbobjc" --delete
```

Set the log level to debug:
```bash
$ Guillotine path/to/index/store path/to/file --debug
```

Make sure that all the paths that you use are **absolute paths**.
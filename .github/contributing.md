# Contributing to MySQLNIO

👋 Welcome to the Vapor team! 

## Testing

To run this package's tests, you need to start a local MySQL database. The easiest way to do this is using Docker.

If you have Docker installed and running, you can use the `docker-compose` included with this package. The following command will download the required files and boot a local MySQL server:

```fish
docker-compose up mysql
```

Run this in the project's root folder (where the `docker-compose.yml` file is). Check out that file to see the other versions of MySQL you can test against.

Once you have a server running, you can run the test suite from Xcode by hitting `CMD+u` or from the command line:

```fish
swift test
```

Make sure to add tests for any new code you write.

----------

Join us on Discord if you have any questions: [http://vapor.team](http://vapor.team).

&mdash; Thanks! 🙌

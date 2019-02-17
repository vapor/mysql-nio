FROM vapor/swift:5.0
COPY . .
ENTRYPOINT swift test

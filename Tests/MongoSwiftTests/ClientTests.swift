@testable import MongoSwift
import Nimble
import XCTest
import libmongoc

final class ClientTests: XCTestCase {
    static var allTests: [(String, (ClientTests) -> () throws -> Void)] {
        return [
            ("testListDatabases", testListDatabases),
            ("testOpaqueInitialization", testOpaqueInitialization)
        ]
    }

    func testListDatabases() throws {
        let client = try MongoClient()
        let databases = try client.listDatabases(options: ListDatabasesOptions(nameOnly: true))
        let expectedDbs: [Document] = [["name": "admin"], ["name": "config"], ["name": "local"]]
        expect(Array(databases) as [Document]).to(equal(expectedDbs))
    }

    func testOpaqueInitialization() throws {
        let connectionString = "mongodb://localhost"
        var error = bson_error_t()
        guard let uri = mongoc_uri_new_with_error(connectionString, &error) else {
            throw MongoError.invalidUri(message: toErrorString(error))
        }

        let client_t = mongoc_client_new_from_uri(uri)
        if client_t == nil {
            throw MongoError.invalidClient()
        }

        let client = MongoClient(fromPointer: client_t!)
        let coll = try client.db("test").collection("foo")
        let insertResult = try coll.insertOne([ "test": 42 ])
        let findResult = try coll.find([ "_id": insertResult!.insertedId ])
        let docs = Array(findResult)
        expect(docs[0]["test"] as? Int).to(equal(42))
    }
}
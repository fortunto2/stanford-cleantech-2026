import CrewKit
import Foundation
import Testing

@Suite struct PlacesTests {
    @Test func decodesSuggestions() throws {
        let json = #"{"q":"fres","places":[{"name":"Fresno","detail":"Fresno, California","lat":36.74773,"#
            + #""lon":-119.77237}]}"#
        let list = try JSONDecoder().decode(PlaceList.self, from: Data(json.utf8))
        #expect(list.places.first?.name == "Fresno")
        #expect(list.places.first?.query == "36.7477,-119.7724")
    }

    @Test func coordinateOrName() {
        #expect(PlaceQuery.isCoordinate("36.7477,-119.7724"))
        #expect(!PlaceQuery.isCoordinate("Fresno"))
        #expect(!PlaceQuery.isCoordinate("Fresno, CA"))
    }
}

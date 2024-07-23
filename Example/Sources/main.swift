// The Swift Programming Language
// https://docs.swift.org/swift-book

struct ExampleApp {
    func run() {
        let a = Person()
        let person = Person(name: "John Doe", id: 1234, email: "john.doe@example.com")
        let addressBook = AddressBook(people: [person])

        print("Name: \(person.name), ID: \(person.id), Email: \(person.email)")
        print("Address Book: \(addressBook)")
    }
}

ExampleApp().run()

// The Swift Programming Language
// https://docs.swift.org/swift-book

func run() {
    let person = Person(name: "John Doe", id: 1234, email: "john.doe@example.com")
    let addressBook = AddressBook(people: [person], isCurrent: false)
    let address = Address(street: "Example Avenue")

    print("Name: \(person.name), ID: \(person.id), Email: \(person.email)")
    print("Address Book: \(addressBook)")
    print("Address street: \(address.street)")
}

run()

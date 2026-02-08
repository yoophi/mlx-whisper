import Foundation

protocol ConfigStoring {
    var recordHotkey: String { get set }
    var langHotkey: String { get set }
    var language: String { get set }
    var model: String { get }
    func save()
}

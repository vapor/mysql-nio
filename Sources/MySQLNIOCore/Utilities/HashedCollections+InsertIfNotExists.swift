import Collections

extension Dictionary {
    @discardableResult
    @inlinable public mutating func addValue(_ value: Value, forKey key: Key) -> Bool {
        guard self[key] == nil else {
            return false
        }
        self[key] = value
        return true
    }
}

extension OrderedDictionary {
    @discardableResult
    @inlinable public mutating func addValue(_ value: Value, forKey key: Key) -> Bool {
        guard self[key] == nil else {
            return false
        }
        self[key] = value
        return true
    }

    @inlinable public subscript(notUpdating key: Key) -> Value? {
        get { self[key] }
        set {
            if let newValue {
                self.addValue(newValue, forKey: key)
            } else {
                self.removeValue(forKey: key)
            }
        }
    }
}

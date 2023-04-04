
extend Array<T> where T <: String{
    public func containsAny(items:Array<String>):Bool {
        for (item in this) {
            if (items.contains(item)) {
                return true
            }
        }
        return false
    }
}

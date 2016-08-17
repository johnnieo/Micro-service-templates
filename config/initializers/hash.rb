class Hash
  def squish_fields!
    each { |_k, v| v.squish! if v.present? && v.is_a?(String) }
    self
  end
end

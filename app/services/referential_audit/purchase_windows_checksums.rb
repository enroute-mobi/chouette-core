class ReferentialAudit
  class PurchaseWindowsChecksums < Base
    def find_faulty
      Chouette::PurchaseWindow.all.map{|p| p.update_checksum}.uniq
    end

    def message
      "Found #{faulty.size - 1} PurchaseWindows with inconsistent Checksums"
    end
  end
end

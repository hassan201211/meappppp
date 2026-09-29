//
//  FileManager+documents.swift
//  Feather
//
//  Created by samara on 11.04.2025.
//

import Foundation

extension FileManager {
    
    /// متغير مساعد للتوافق مع iOS 15 مع الحفاظ على كود iOS 16
    private var compatibleDocumentsDirectory: URL {
        if #available(iOS 16.0, *) {
            return URL.documentsDirectory
        } else {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
    }

    /// Gives apps Archives directory
    var archives: URL {
        compatibleDocumentsDirectory.appendingPathComponent("Archives")
    }
    
    /// Gives apps Signed directory
    var signed: URL {
        compatibleDocumentsDirectory.appendingPathComponent("Signed")
    }
    
    /// Gives apps Signed directory with a UUID appending path
    func signed(_ uuid: String) -> URL {
        signed.appendingPathComponent(uuid)
    }
    
    /// Gives apps Unsigned directory
    var unsigned: URL {
        compatibleDocumentsDirectory.appendingPathComponent("Unsigned")
    }
    
    /// Gives apps Unsigned directory with a UUID appending path
    func unsigned(_ uuid: String) -> URL {
        unsigned.appendingPathComponent(uuid)
    }
    
    /// Gives apps Certificates directory
    var certificates: URL {
        compatibleDocumentsDirectory.appendingPathComponent("Certificates")
    }
    
    /// Gives apps Certificates directory with a UUID appending path
    func certificates(_ uuid: String) -> URL {
        certificates.appendingPathComponent(uuid)
    }
}

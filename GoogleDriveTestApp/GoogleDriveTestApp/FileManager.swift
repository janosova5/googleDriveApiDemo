//
//  FileManager.swift
//  GoogleDriveTestApp
//
//  Created by ljanosova on 6.2.19.
//  Copyright © 2019 ljanosova. All rights reserved.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

final class FileManagerService {
    
    private let service: GTLRDriveService
    
    init(_ service: GTLRDriveService) {
        self.service = service
    }
    
    public func search(_ fileName: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let query = GTLRDriveQuery_FilesList.query()
        query.pageSize = 1
        query.q = "name contains '\(fileName)'"
        
        service.executeQuery(query) { (ticket, results, error) in
            onCompleted((results as? GTLRDrive_FileList)?.files?.first?.identifier, error)
        }
    }
    
    public func download(_ fileID: String, onCompleted: @escaping (Data?, Error?) -> ()) {
        
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileID)
        service.executeQuery(query) { (ticket, file, error) in
            onCompleted((file as? GTLRDataObject)?.data, error)
        }
    }
    
    public func createFolder(_ name: String, onCompleted: @escaping (String?, Error?) -> ()) {
        let file = GTLRDrive_File()
    
        file.name = name
        file.mimeType = "application/vnd.google-apps.folder"
            
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: nil)
        query.fields = "id"
            
        service.executeQuery(query) { (ticket, folder, error) in
            onCompleted((folder as? GTLRDrive_File)?.identifier, error)
        }
    }
    
    public func uploadFile(_ folderName: String, filePath: String, MIMEType: String, onCompleted: ((String?, Error?) -> ())?) {
        
        search(folderName) { (folderID, error) in
            
            if let ID = folderID {
                
                self.upload(ID, path: filePath, MIMEType: MIMEType, onCompleted: onCompleted)
            } else {
                self.createFolder(folderName, onCompleted: { (folderID, error) in
                    guard let ID = folderID else {
                        onCompleted?(nil, error)
                        return
                    }
                    self.upload(ID, path: filePath, MIMEType: MIMEType, onCompleted: onCompleted)
                })
            }
        }
    }
    
    private func upload(_ parentID: String, path: String, MIMEType: String, onCompleted: ((String?, Error?) -> ())?) {
        
        guard let data = FileManager.default.contents(atPath: path) else {
            onCompleted?(nil, nil)
            return
        }
        
        let file = GTLRDrive_File()
        file.name = path.components(separatedBy: "/").last
        file.parents = [parentID]
        
        
        let uploadParams = GTLRUploadParameters.init(data: data, mimeType: MIMEType)
        uploadParams.shouldUploadWithSingleRequest = true
            
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParams)
        query.fields = "id,webViewLink,webContentLink,fullFileExtension,iconLink,permissions"
            
        self.service.executeQuery(query, completionHandler: { (ticket, uploadedFile, error) in
                
            if let fileID = (uploadedFile as? GTLRDrive_File)?.identifier {
                let permissions = GTLRDrive_Permission.init()
                permissions.type = "anyone"
                permissions.role = "reader"
                    
                let permissionsQuery = GTLRDriveQuery_PermissionsCreate.query(withObject: permissions, fileId: fileID)
                permissionsQuery.fields = "id,type,role"
                
                self.service.executeQuery(permissionsQuery, completionHandler: { (ticket, permissions, error) in
                    onCompleted?((uploadedFile as? GTLRDrive_File)?.identifier, error)
                })
            }
        })
    }
}

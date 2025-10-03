// MockData.swift
#if DEBUG
import Foundation

// MARK: - SupabaseUser Mocks
extension SupabaseUser {
    
    // MARK: Basic Mocks (sin relaciones)
    
    static var mockPending: SupabaseUser {
        SupabaseUser(
            id: UUID(),
            displayName: "Juan Pérez",
            email: "juan.pending@test.com",
            phone: "+56912345678",
            country: "CL",
            kycStatus: .kycPending,
            defaultCurrency: "CLP",
            pinSet: false,
            createdAt: Date().addingTimeInterval(-86400 * 7), // 7 días atrás
            updatedAt: Date().addingTimeInterval(-3600) // 1 hora atrás
        )
    }
    
    static var mockReview: SupabaseUser {
        SupabaseUser(
            id: UUID(),
            displayName: "María González",
            email: "maria.review@test.com",
            phone: "+56987654321",
            country: "CL",
            kycStatus: .kycReview,
            defaultCurrency: "CLP",
            pinSet: true,
            createdAt: Date().addingTimeInterval(-86400 * 14), // 14 días atrás
            updatedAt: Date().addingTimeInterval(-7200) // 2 horas atrás
        )
    }
    
    static var mockVerified: SupabaseUser {
        SupabaseUser(
            id: UUID(),
            displayName: "Carlos Rodríguez",
            email: "carlos.verified@test.com",
            phone: "+56911223344",
            country: "CL",
            kycStatus: .kycVerified,
            defaultCurrency: "CLP",
            pinSet: true,
            createdAt: Date().addingTimeInterval(-86400 * 30), // 30 días atrás
            updatedAt: Date().addingTimeInterval(-3600 * 12) // 12 horas atrás
        )
    }
    
    static var mockRejected: SupabaseUser {
        SupabaseUser(
            id: UUID(),
            displayName: "Ana Silva",
            email: "ana.rejected@test.com",
            phone: "+56955667788",
            country: "CL",
            kycStatus: .kycRejected,
            defaultCurrency: "CLP",
            pinSet: false,
            createdAt: Date().addingTimeInterval(-86400 * 5), // 5 días atrás
            updatedAt: Date().addingTimeInterval(-1800) // 30 min atrás
        )
    }
    
    // MARK: Variantes sin datos opcionales
    
    static var mockMinimal: SupabaseUser {
        SupabaseUser(
            id: UUID(),
            displayName: "Usuario Mínimo",
            email: "minimal@test.com",
            phone: nil,
            country: nil,
            kycStatus: .kycPending,
            defaultCurrency: "CLP",
            pinSet: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    static var mockNewUser: SupabaseUser {
        SupabaseUser(
            id: UUID(),
            displayName: "Nuevo Usuario",
            email: "nuevo@test.com",
            phone: "+56900000000",
            country: "CL",
            kycStatus: .kycPending,
            defaultCurrency: "CLP",
            pinSet: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: Usuarios de otros países
    
    static var mockArgentina: SupabaseUser {
        SupabaseUser(
            id: UUID(),
            displayName: "Diego Maradona",
            email: "diego@test.ar",
            phone: "+541144445555",
            country: "AR",
            kycStatus: .kycVerified,
            defaultCurrency: "ARS",
            pinSet: true,
            createdAt: Date().addingTimeInterval(-86400 * 60),
            updatedAt: Date().addingTimeInterval(-86400)
        )
    }
    
    static var mockMexico: SupabaseUser {
        SupabaseUser(
            id: UUID(),
            displayName: "Frida Kahlo",
            email: "frida@test.mx",
            phone: "+525555555555",
            country: "MX",
            kycStatus: .kycVerified,
            defaultCurrency: "MXN",
            pinSet: true,
            createdAt: Date().addingTimeInterval(-86400 * 90),
            updatedAt: Date().addingTimeInterval(-86400 * 2)
        )
    }
    
//    // MARK: Mocks con relaciones completas
//    
//    static var mockWithCampaigns: SupabaseUser {
//        var user = mockVerified
//        user.campaigns = [
//            .mockActive,
//            .mockCompleted,
//            .mockDraft
//        ]
//        user.donations = [
//            .mockPaid,
//            .mockPending
//        ]
//        return user
//    }
//    
//    static var mockWithKYCDocuments: SupabaseUser {
//        var user = mockReview
//        user.kycDocuments = [
//            .mockApproved,
//            .mockPending,
//            .mockRejected
//        ]
//        return user
//    }
//    
//    static var mockCampaignOwner: SupabaseUser {
//        var user = mockVerified
//        user.campaigns = [
//            .mockActive,
//            .mockCompleted
//        ]
//        user.vaultItems = [
//            .mockPublic,
//            .mockPrivate
//        ]
//        return user
//    }
//    
//    static var mockDonor: SupabaseUser {
//        var user = mockVerified
//        user.donations = [
//            .mockPaid,
//            .mockPaid,
//            .mockPaid
//        ]
//        return user
//    }
//    
//    static var mockBeneficiary: SupabaseUser {
//        var user = mockVerified
//        user.beneficiaries = [
//            .mockActiveBeneficiary
//        ]
//        return user
//    }
//    
    // MARK: Casos edge
    
    static var mockLongName: SupabaseUser {
        SupabaseUser(
            id: UUID(),
            displayName: "María Fernanda Gabriela Rodríguez Hernández de la Cruz",
            email: "maria.larga@test.com",
            phone: "+56912345678",
            country: "CL",
            kycStatus: .kycVerified,
            defaultCurrency: "CLP",
            pinSet: true,
            createdAt: Date().addingTimeInterval(-86400 * 45),
            updatedAt: Date()
        )
    }
    
    static var mockNoPhone: SupabaseUser {
        SupabaseUser(
            id: UUID(),
            displayName: "Sin Teléfono",
            email: "sin.telefono@test.com",
            phone: nil,
            country: "CL",
            kycStatus: .kycPending,
            defaultCurrency: "CLP",
            pinSet: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: Helpers para crear usuarios personalizados
    
    static func mock(
        displayName: String = "Test User",
        email: String = "test@test.com",
        kycStatus: KYCStatusSupabase = .kycPending,
        country: String = "CL",
        pinSet: Bool = false
    ) -> SupabaseUser {
        SupabaseUser(
            id: UUID(),
            displayName: displayName,
            email: email,
            phone: "+56912345678",
            country: country,
            kycStatus: kycStatus,
            defaultCurrency: "CLP",
            pinSet: pinSet,
            createdAt: Date().addingTimeInterval(-86400 * 10),
            updatedAt: Date()
        )
    }
}

// MARK: - Array Extensions para testing
extension Array where Element == SupabaseUser {
    static var mockUserList: [SupabaseUser] {
        [
            .mockVerified,
            .mockReview,
            .mockPending,
            .mockRejected
        ]
    }
    
    static var mockVerifiedUsers: [SupabaseUser] {
        [
            .mockVerified,
            .mockArgentina,
            .mockMexico
        ]
    }
}

extension AppState {
    static func mockState(withUser user: SupabaseUser) -> AppState {
        let state = AppState()
        state.currentUser = user
        return state
    }
    
    // Helpers para casos comunes
    static var mockPending: AppState { mockState(withUser: .mockPending) }
    static var mockReview: AppState { mockState(withUser: .mockReview) }
    static var mockVerified: AppState { mockState(withUser: .mockVerified) }
    static var mockRejected: AppState { mockState(withUser: .mockRejected) }
}


#endif

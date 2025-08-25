//
//  DescriptionLark.swift
//  L-ark
//
//  Created by Jose Rodriguez on 25-08-25.
//

/*
 Claro, una buena arquitectura de directorios en Xcode es fundamental para mantener el proyecto ordenado, escalable y fácil de navegar. Te propongo una estructura limpia y moderna, basada en el patrón de diseño MVVM (Model-View-ViewModel), que es muy popular en el desarrollo con SwiftUI.

 Arquitectura de Directorios Sugerida
 Esta estructura separa el código por funcionalidad (Features) en lugar de por tipo de archivo, lo que hace mucho más fácil encontrar todo lo relacionado con una pantalla o característica específica.

 Aquí tienes un diagrama en formato de texto que puedes replicar directamente en Xcode:

 📁 TuNombreDeApp
 ├── 📁 Application
 │   ├──  AppDelegate.swift
 │   ├── TuNombreDeAppApp.swift
 │   └── Info.plist
 │
 ├── 📁 Core
 │   ├── 📂 Authentication
 │   │   └── AuthService.swift
 │   ├── 📂 DataModels
 │   │   ├── User.swift
 │   │   └── ProjectLegacy.swift
 │   ├── 📂 Networking
 │   │   └── PaymentGatewayService.swift
 │   └── 📂 Managers
 │       └── FirebaseManager.swift
 │
 ├── 📁 Features
 │   ├── 📂 Onboarding
 │   │   ├── Views
 │   │   │   ├── LoginView.swift
 │   │   │   └── VerificationView.swift
 │   │   └── ViewModels
 │   │       └── OnboardingViewModel.swift
 │   │
 │   ├── 📂 ProjectLegacy
 │   │   ├── 📂 CreateProject
 │   │   │   ├── Views
 │   │   │   │   └── CreateProjectView.swift
 │   │   │   └── ViewModels
 │   │   │       └── CreateProjectViewModel.swift
 │   │   ├── 📂 ProjectDetail
 │   │   │   ├── Views
 │   │   │   │   └── ProjectDetailView.swift
 │   │   │   └── ViewModels
 │   │   │       └── ProjectDetailViewModel.swift
 │   │   └── 📂 FundRelease
 │   │       ├── Views
 │   │       │   └── FundReleaseView.swift
 │   │       └── ViewModels
 │   │           └── FundReleaseViewModel.swift
 │   │
 │   └── 📂 UserProfile
 │       ├── Views
 │       │   └── UserProfileView.swift
 │       └── ViewModels
 │           └── UserProfileViewModel.swift
 │
 ├── 📁 Extensions
 │   ├── Color+Extension.swift
 │   └── View+Extension.swift
 │
 ├── 📁 Utils
 │   └── Constants.swift
 │
 └── 📁 Resources
     ├── Assets.xcassets
     └── Preview Content
 Explicación de Cada Directorio
 📁 Application: Contiene los archivos de configuración y ciclo de vida de la aplicación. Aquí va el AppDelegate y el archivo principal de la app que define la escena inicial.

 📁 Core: Este es el corazón de tu lógica de negocio y servicios compartidos.

 Authentication: Maneja toda la lógica de inicio de sesión, registro y gestión de sesiones con Firebase Auth.

 DataModels: Define las estructuras de tus datos (struct User, struct ProjectLegacy). Son los "Model" en MVVM.

 Networking/Services: Clases que se comunican con servicios externos, como tu pasarela de pagos.

 Managers: Clases de ayuda globales. Un FirebaseManager podría centralizar la configuración y el acceso a Firestore y Storage.

 📁 Features: ¡La parte más importante! Cada subcarpeta aquí representa una funcionalidad o pantalla principal de tu app. Dentro de cada una, separamos las Vistas (Views) de la lógica de presentación (ViewModels).

 Onboarding: Flujo de registro y verificación.

 ProjectLegacy: Todo lo relacionado con los "Proyectos Legado". Lo he subdividido en CreateProject, ProjectDetail (la vista pública) y FundRelease (el flujo de activación).

 UserProfile: La pantalla de perfil del usuario.

 📁 Extensions: Un lugar para extender la funcionalidad de clases existentes de Apple. Por ejemplo, para definir colores personalizados (Color+Extension) o crear modificadores de vista reutilizables (View+Extension).

 📁 Utils: Un cajón de sastre para utilidades y constantes que no encajan en otro lugar. Un archivo Constants.swift es útil para guardar valores fijos como URLs, claves de API, etc.

 📁 Resources: Aquí van los recursos visuales de tu app, principalmente el Assets.xcassets, donde guardas tus imágenes, íconos y defines tus colores.

 Esta estructura te dará una base sólida, organizada y profesional para empezar a construir tu MVP.
 
 
 
 
 
 
 */

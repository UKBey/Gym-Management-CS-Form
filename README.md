# Gym Membership Management System

This is a C# Windows Forms desktop application developed to manage gym memberships, users, and membership plans. It utilizes PostgreSQL as the backend database and Entity Framework Core as the ORM for database operations. The application provides a clean form-based UI for performing all CRUD operations.

---

## 🚀 Features

- Add, update, and delete gym members
- Manage membership plans and user information
- Form validations and user-friendly interface
- PostgreSQL database integration via Entity Framework Core
- Object-Oriented Programming structure
- Local deployment with Visual Studio

---

## 🧱 Technologies Used

- **C#** – Primary programming language
- **Windows Forms** – Desktop UI framework
- **PostgreSQL** – Relational database
- **Entity Framework Core** – ORM for data access
- **ADO.NET** – Supplemental database connectivity
- **Visual Studio** – Development environment

---

## 📁 Project Structure Overview

```
GymManagement/
├── Forms/                 → Windows Forms for members, plans, login, etc.
├── Models/                → Classes representing entities
├── Database/              → Connection and EF Core configuration
├── gym_management_db.sql  → SQL script for initial database
├── Program.cs             → Application entry point
└── app.config             → Database connection settings
```

---

## ⚙️ How to Run

1. Open the solution file (`.sln`) in Visual Studio.
2. Make sure PostgreSQL is installed and the database is created using the `gym_management_db.sql` file.
3. Update the connection string in `app.config` if necessary.
4. Build and run the project.

---

## 👤 Author

**Ukbe Taha Şahinkaya**  

---

## 📄 License

This project is provided for educational and portfolio purposes.

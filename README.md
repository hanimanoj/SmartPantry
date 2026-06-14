# Smart Pantry Proposal

<h1>Group 5 Members</h1>

- AINUL HANI BINTI MANOJ (2314784) ; Dashboard & Analystics
- FARRESA HAIFA' BINTI MOHAMMED (2319554) ; Login & Authentication Module
- BALQIS BINTI MUHAMMAD MA'AMUN (2314074) ; Media & Storage
- LAILA KARMILA BINTI SHAHRUNIZAM (2313814) ; Pantry Management

<h1>1. Introduction </h1>
  Lately, a lot of people experience food waste among the products that they bought, because of poor tracking of product expiration date. Many people also seldomly forgot items in their pantry that leads to unnecessary waste. To avoid this issue, we proposed a Smart Pantry application. 
<h1>2. Objective </h1>

- Develop a mobile application that allows user to keep track of the products they bought including the expiration date
- Provide real-time tracking of items inside pantry with status (safe, almost expired, expired)
- Implement notification alerts to alert users on the product that is reaching the expiration date
- Practice sustainability by reducing food waste

<h1>3. Target User </h1>

- Household residents who wants to manage pantry items efficiently
- People who live in shared accomodations who need reminders for food safety
- Elderly people who may forget the expiration date

<h1>4. ⁠⁠Features and Functionality </h1>
    <h2>4.1 LOGIN</h2>
   
      a. User Authentication
          - Users can log in using email and password
          - Authentication is handled using Firebase Authentication
          - System verifies user credentials securely before granting access
    
      b. Input Validation
          - Email field validation (must follow proper email format)
          - Password field validation (minimum length requirement, e.g., 6+ characters)
          - Error messages shown for:(Invalid email format, Incorrect Password, Empty fields)

   <h2>4.2 HOMEPAGE & DASHBOARD</h2>
   
       - Display item that nearly to expired
       - Display pantry summary 
       - Add item features

  <h2>4.3 ADD ITEM PAGE</h2>
  
        - Users can add item details and picture
        - Users will set the expiry date
        - Users can choose to save or cancel the entry

  <h2>4.4 SNAP ITEM</h2>

        - Users can capture a picture of the item
        - Users can upload a picture from the phone gallery

  <h2>4.5 NOTIFICATIONS</h2>

        - Send periodic reminders about item expiry dates
        - Send friendly nudges (e.g. our pantry is looking organized — nice work, Hungry? You’ve got some breads., etc.)
        - Send action confirmations (e.g. adding, editing, or deleting items)

  <h2>4.6 HISTORY</h2>
  
        - Record and display past actions (e.g. adding, editing, or deleting items)

<h1>5. UI Mockup </h1> 
   <img width="233" height="479" alt="image" src="https://github.com/user-attachments/assets/d870b045-1da0-4db9-b881-68662cd07709" /> <img width="238" height="479" alt="image" src="https://github.com/user-attachments/assets/9c8a70d2-02a9-4c72-84f4-e3b627cb082c" /> <img width="238" height="479" alt="Screenshot 2026-06-04 193707" src="https://github.com/user-attachments/assets/45a6db5c-d00a-4b17-9057-d2900ccc847e" /> <img width="233" height="479" alt="image" src="https://github.com/user-attachments/assets/b9f192c9-ee22-47fa-af3d-62ff340085f9" /> <img width="233" height="479" alt="image" src="https://github.com/user-attachments/assets/c57c7d12-c894-40cc-9f8e-4b0d02e9ac36" /> <img width="233" height="479" alt="image" src="https://github.com/user-attachments/assets/a1e5cf05-0874-45e0-af6f-902cb35865e1" />

<h1>6. Architecture </h1>
   <h2>6.1 Widgets & Components Structure</h2>
     <img width="363" height="306" alt="image" src="https://github.com/user-attachments/assets/965eee7f-d285-438f-88ff-ae3cb3b77322" /> <br>
    <h2>6.2 State Management Approach</h2>
      The Smart Pantry application will use Provider as its state management solution. Provider enables efficient data sharing across widgets while maintaining a clear separation between the user interface and business logic. It is lightweight, easy to implement, and well-suited for Firebase-based applications. Provider will be used to manage authentication status, pantry item data, image storage operations, and dashboard analytics throughout the application.


<h1>7. ⁠Data model </h1> 
<img width="359" height="326" alt="image" src="https://github.com/user-attachments/assets/5ac99a32-76c0-4fff-b83b-1f839f3aa549" />



<h1>8. ⁠Flowchart </h1> 
<img width="175" height="521" alt="image" src="https://github.com/user-attachments/assets/2b86a51c-fa80-4067-8eaa-83b2b9f7202f" />


<h1>9. References</h1>
  App Store. (n.d.). NoWaste: Food Inventory List App - App Store. https://apps.apple.com/my/app/nowaste-food-inventory-list/id926211004
  <br>Smart Pantry - apps on Google Play. (n.d.). https://play.google.com/store/apps/details?id=com.smartpantry

# Smart Pantry Proposal

<h1>1. Introduction (lela)</h1>
  
<h1>2. Objective (lela)</h1>

<h1>3. Target User (lela)</h1>


<h1>4. ⁠⁠Features and Functionality (semua)</h1>
    <h2>4.1 LOGIN</h2>
   
      a. User Authentication
          - Users can log in using email and password
          - Authentication is handled using Firebase Authentication
          - System verifies user credentials securely before granting access
    
      b. Input Validation
          - Email field validation (must follow proper email format)
          - Password field validation (minimum length requirement, e.g., 6+ characters)
          - Error messages shown for:(Invalid email format, Incorrect Password, Empty fields)

   <h2>4.2 HOMEPGAE & DASHBOARD</h2>
   
       - Display item that nearly to expired
       - Display pantry summary 
       - Add item features

<h1>5. UI Mockup (semua)</h1> 
   <img width="233" height="479" alt="image" src="https://github.com/user-attachments/assets/d870b045-1da0-4db9-b881-68662cd07709" /> <img width="238" height="479" alt="image" src="https://github.com/user-attachments/assets/9c8a70d2-02a9-4c72-84f4-e3b627cb082c" />



  
<h1>6. Architecture (balqis)</h1>
   <h2>6.1 Widgets & Components Structure</h2>
     <img width="363" height="306" alt="image" src="https://github.com/user-attachments/assets/965eee7f-d285-438f-88ff-ae3cb3b77322" /> <br>
    <h2>6.2 State Management Approach</h2>
      The Smart Pantry application will use Provider as its state management solution. Provider enables efficient data sharing across widgets while maintaining a clear separation between the user interface and business logic. It is lightweight, easy to implement, and well-suited for Firebase-based applications. Provider will be used to manage authentication status, pantry item data, image storage operations, and dashboard analytics throughout the application.


<h1>7. ⁠Data model (hani)</h1> 
<img width="359" height="226" alt="image" src="https://github.com/user-attachments/assets/5ac99a32-76c0-4fff-b83b-1f839f3aa549" />



<h1>8. ⁠Flowchart (haifa)</h1> 
<img width="175" height="521" alt="image" src="https://github.com/user-attachments/assets/2b86a51c-fa80-4067-8eaa-83b2b9f7202f" />


<h1>9. References</h1>
  App Store. (n.d.). NoWaste: Food Inventory List App - App Store. https://apps.apple.com/my/app/nowaste-food-inventory-list/id926211004
  <br>Smart Pantry - apps on Google Play. (n.d.). https://play.google.com/store/apps/details?id=com.smartpantry

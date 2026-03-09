Prac 8
Kali root terminal(first check ansible –version if not there )
sudo apt update
sudo apt –allow-insecure-repositories
sudo apt install kali-archive-keyring –reinstall
sudo abt install Ansible
ansible –version
nano install_nginx.yml
--- 
- name: Install and Start NGINX 
  hosts: localhost 
  become: yes 
 
  tasks: 
    - name: Install NGINX 
      apt: 
        name: nginx         
state: present 
 
    - name: Start Nginx service 
      service: 
        name: nginx         
state: started 
 
    - name: Create a file 
      file:  
        path: /home/kali/demo.txt         
state: touch 



run yml file
ls
ansible-playbook -i hosts install_ngnix.yml --ask-become-pass
ls -i ~/demo.txt
/var/www/html
Ls
Sudo rm index.html

Cicd github
node {
    stage('DEV') {
        echo 'Cloning GitHub repository'
        git branch: 'main',
            url: 'https://github.com/Snehal0335/cc_ampify.git'
    }
    stage('QA') {
        input 'QA DEPLOY?'
    }
    stage('DEPLOY TO PROD') {
    bat 'xcopy "index.html" "C:\\Users\\Snehal\\Downloads\\apache-tomcat-11.0.18\\apache-tomcat-11.0.18\\webapps\\ROOT" /Y'
    }
}


